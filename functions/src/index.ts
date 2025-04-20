/* eslint-disable max-len, no-irregular-whitespace */

import * as logger from "firebase-functions/logger";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {VertexAI} from "@google-cloud/vertexai";

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
