const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const cors = require("cors")({ origin: true });

exports.extractBillData = onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      // 1. Block unauthorized request types
      if (req.method !== "POST") {
        return res.status(405).send("Method Not Allowed");
      }

      // 2. Grab the prompt and image payload from the mobile app
      const { prompt, base64Image } = req.body;
      if (!prompt || !base64Image) {
        return res.status(400).send("Missing prompt or image data.");
      }

      // 3. Initialize Gemini securely using the server's hidden environment variable
      const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
      const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

      // 4. Format the image exactly how Gemini expects it
      const imagePart = {
        inlineData: {
          data: base64Image,
          mimeType: "image/jpeg"
        }
      };

      // 5. Fire the extraction request
      logger.info("Sending document to Gemini...");
      const result = await model.generateContent([prompt, imagePart]);
      const responseText = result.response.text();

      // 6. Send the extracted text back to the mobile app to be pasted
      res.status(200).json({ extractedData: responseText });

    } catch (error) {
      logger.error("Gemini Error:", error);
      res.status(500).send("Server Error parsing document.");
    }
  });
});
