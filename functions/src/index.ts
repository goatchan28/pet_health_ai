/* eslint-disable max-len, no-irregular-whitespace */

import * as logger from "firebase-functions/logger";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import {VertexAI} from "@google-cloud/vertexai";
import {DateTime} from "luxon";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

admin.initializeApp();

const projectId =
  process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT;

if (!projectId) {
  throw new Error("Project ID environment variable is missing");
}

const vertex = new VertexAI({
  project: projectId, // <-- no '!'
  location: "us-central1",
});

const model = vertex.preview.getGenerativeModel({
  model: "gemini-2.0-flash-001",
});

export const scanCreated = onDocumentCreated(
  "packageScans/{scanID}",
  async (snap) => {
    const scanID = snap.params.scanID;
    const data = snap.data?.data();

    if (!data?.frontPath || !data?.backPath) {
      logger.error("Missing image paths for", scanID, data);
      await snap.data?.ref.update({
        status: "error",
        message: "Missing image paths",
      });
      return;
    }

    const bucketName = admin.storage().bucket().name;
    const frontUri = `gs://${bucketName}/${data.frontPath}`;
    const backUri = `gs://${bucketName}/${data.backPath}`;

    logger.log("New package scan", scanID, data);
    await snap.data?.ref.update({status: "processing"});
    logger.log("Processing scan", scanID);

    try {
      /* ── 1.  Call Gemini 1.5 Pro Vision ─────────────────────── */
      const {response} = await model.generateContent({
        contents: [
          {
            role: "user",
            parts: [
              {
                text: `You are an expert at reading pet‑food Guaranteed‑Analysis (GA) panels.

                        Return ONLY minified JSON exactly like:
                        {"productName":"","brandName":"",
                        "guaranteedAnalysis":{
                        "Crude Protein":0,"Crude Fat":0,"Calcium":0,"Moisture":0
                        },
                        "Calories":0,
                        "missing":[]}

                        Rules
                        • Keys & spelling must match the example (incl. spaces / capitals).
                        • GA values & Moisture = percentages; 
                        • Calories must be reported **as kcal per 100 g**:
                            – If the label shows kcal/kg, divide by 10.
                        • If a label uses a synonym, map it to the required key
                        (e.g. "Protein" → Crude Protein, "Water" → Moisture, etc.).
                        • If a value is absent or unreadable, set it to 0 **and add its key to "missing"**.
                        • Do NOT output extra keys, markdown, or prose.`,
              },
              {fileData: {mimeType: "image/jpeg", fileUri: frontUri}},
              {fileData: {mimeType: "image/jpeg", fileUri: backUri}},
            ],
          },
        ],
        generationConfig: {
          responseMimeType: "application/json", // strict JSON
        },
      });

      /* ── 2.  Parse the JSON ----------------------------------------------------------------- */
      const firstCand = response.candidates?.[0];
      const firstPart = firstCand?.content?.parts?.[0];
      const rawText = firstPart?.text;

      if (!rawText) {
        // Nothing came back from Gemini → let the outer catch handle it
        throw new Error("Empty or malformed Gemini response");
      }

      const parsed = JSON.parse(rawText) as {
        productName: string;
        brandName: string;
        guaranteedAnalysis: {
            "Crude Protein": number;
            "Crude Fat": number;
            "Calcium": number;
            "Moisture": number;
        };
        Calories: number;
        missing: string[];
        };

      logger.log("Gemini parsed", parsed);


      /* ── 3.  Use the *barcode you already have* (data.barcode) ------------------------------ */
      const barcode = data.barcode as string; // stored earlier by client
      await admin.firestore()
        .collection("foods")
        .doc(barcode)
        .set(
          {
            productName: parsed.productName,
            brandName: parsed.brandName,
            guaranteedAnalysis: parsed.guaranteedAnalysis,
            caloriesPer100g: parsed.Calories,
            missing: parsed.missing, // optional
            frontImage: data.frontPath,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true}
        );

      /* optional: delete the back photo */
      // …
      const bucket = admin.storage().bucket(); // 👈 get the default bucket
      await bucket.file(data.backPath).delete().catch((err) => {
        if (err.code !== 404) logger.warn("Could not delete back image", err);
      });

      await snap.data?.ref.update({status: "done"});
    } catch (err) {
      logger.error("Gemini error", err);
      await snap.data?.ref.update({
        status: "error",
        message: (err as Error).message ?? "Gemini failure",
      });
    }
  }
);


const blankDay = {
  "Calories": 0,
  "Carbohydrates": 0,
  "Crude Fat": 0,
  "Crude Protein": 0,
} as const;

const initializeWeeklyNutrients = () => ({
  Monday: {...blankDay},
  Tuesday: {...blankDay},
  Wednesday: {...blankDay},
  Thursday: {...blankDay},
  Friday: {...blankDay},
  Saturday: {...blankDay},
  Sunday: {...blankDay},
});


export const dailyReset = onSchedule(
  {schedule: "0 0 * * *", timeZone: "America/New_York"},
  async () => {
    const nowNY = DateTime.now().setZone("America/New_York");
    const yestNY = nowNY.minus({days: 1});
    const dayName = yestNY.toFormat("EEEE"); // Monday … Sunday
    const today = nowNY.toISODate(); // "2025-04-27"

    const sysRef = admin.firestore().doc("system/dailyReset");
    if ((await sysRef.get()).data()?.lastResetDate === today) {
      logger.log("dailyReset: already ran today, skipping.");
      return;
    }

    logger.log(`dailyReset: archiving ${dayName}, zeroing counters…`);
    const petsSnap = await admin.firestore().collection("pets").get();
    const bw = admin.firestore().bulkWriter();

    petsSnap.forEach((d) => {
      const p = d.data();
      const intake = p.nutritionalIntake ?? {};

      // ----- 1. archive yesterday’s totals -----
      if (dayName === "Saturday") {
        bw.update(d.ref, {weeklyNutrients: initializeWeeklyNutrients()});
      } else {
        const wp = (n: string) => `weeklyNutrients.${dayName}.${n}`;
        bw.update(d.ref, {
          [wp("Carbohydrates")]: Number(intake["Carbohydrates"] ?? 0),
          [wp("Crude Protein")]: Number(intake["Crude Protein"] ?? 0),
          [wp("Crude Fat")]: Number(intake["Crude Fat"] ?? 0),
          [wp("Calories")]: Number(p.calorieIntake ?? 0),
        });
      }
      // ----- 2. zero today’s counters -----
      bw.update(d.ref, {
        calorieIntake: 0,
        nutritionalIntake: {}, // same empty map client uses
        mealLog: [],
        exerciseLog: [],
      });
    });

    await bw.close();
    await sysRef.set({lastResetDate: today});
    logger.log(`dailyReset: processed ${petsSnap.size} pets`);
  }
);

export const cleanupUser = functions.auth.user().onDelete(async (user: functions.auth.UserRecord) => {
  const uid = user.uid;
  const db = admin.firestore();

  /* 1. remove the user doc (ignore “not-found”) */
  await db.doc(`users/${uid}`).delete().catch((err: any) => {
    if (err.code !== 5) throw err; // Firestore ‘not-found’ = code 5
  });

  /* 2. unlink (or delete) any pets that reference this uid */
  const petsSnap = await db
    .collection("pets")
    .where("ownerUID", "array-contains", uid)
    .get();

  const bw = db.bulkWriter();
  petsSnap.forEach((doc) => {
    const owners = doc.get("ownerUID") as string[];
    const remaining = owners.filter((o) => o !== uid);

    remaining.length === 0 ?
      bw.delete(doc.ref) : // no owners left → delete pet
      bw.update(doc.ref, {ownerUID: remaining}); // otherwise just unlink
  });

  await bw.close();
  logger.log(`✅ processed ${petsSnap.size} pet(s) for uid ${uid}`);
});

export const weeklyScanCleanup = onSchedule(
  {
    schedule: "15 3 * * SAT", // every Saturday 03:15 AM
    timeZone: "America/New_York",
  },
  async () => {
    const fs = admin.firestore();
    const bucket = admin.storage().bucket();

    /* 1️⃣ collect all *current* front-image paths */
    const foodSnap = await fs.collection("foods").select("frontImage").get();
    const valid = new Set<string>();
    foodSnap.forEach((d) => {
      const p = d.get("frontImage") as string | undefined;
      if (typeof p === "string" && p.trim()) valid.add(p);
    });
    logger.log(`weeklyScanCleanup ▶︎ ${valid.size} valid food images`);

    /* 2️⃣ list every front.jpg we have under package-scans/ */
    const [files] = await bucket.getFiles({prefix: "package-scans/"});
    const orphanIds = new Set<string>();

    for (const f of files) {
      const name = f.name; // e.g. package-scans/abc/front.jpg
      if (!name.endsWith("/front.jpg")) continue;
      if (!valid.has(name)) {
        const scanId = name.split("/")[1];
        orphanIds.add(scanId);
      }
    }
    logger.log(`weeklyScanCleanup ▶︎ ${orphanIds.size} orphan folder(s) found`);

    /* 3️⃣ delete the orphans (storage + Firestore) */
    const bw = fs.bulkWriter();
    await Promise.all(
      Array.from(orphanIds).map(async (id) => {
        // remove all objects below package-scans/<id>/
        await bucket.deleteFiles({prefix: `package-scans/${id}/`});
        // remove the scan document (skip if it never existed)
        bw.delete(fs.doc(`packageScans/${id}`));
      }),
    );
    await bw.close();

    logger.log(`weeklyScanCleanup ✅ removed ${orphanIds.size} folder(s)`);
  },
);
