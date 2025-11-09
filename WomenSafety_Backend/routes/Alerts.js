const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const AlertModel = require('../models/Alert');
const ContactModel = require('../models/Contact');

let twilioClient = null;
const enableTwilio = (process.env.ENABLE_TWILIO === 'true' || process.env.ENABLE_TWILIO === '1');

if (enableTwilio) {
  const twilio = require('twilio');
  if (!process.env.TWILIO_ACCOUNT_SID || !process.env.TWILIO_AUTH_TOKEN) {
    console.warn('⚠️ Twilio enabled but missing SID or Auth Token.');
  } else {
    twilioClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
    console.log('✅ Twilio client initialized successfully.');
  }
} else {
  console.log('ℹ️ Twilio is disabled. SMS will be simulated in logs.');
}

// Helper: Validate latitude & longitude
function isValidLatLng(lat, lng) {
  if (lat === undefined || lng === undefined) return false;
  const nLat = Number(lat);
  const nLng = Number(lng);
  return !Number.isNaN(nLat) && !Number.isNaN(nLng) && nLat >= -90 && nLat <= 90 && nLng >= -180 && nLng <= 180;
}

// Create alert (POST /api/alerts)
router.post('/', auth, async (req, res) => {
  try {
    const { latitude, longitude, message, contactIds } = req.body;

    if (message && message.length > 1000) {
      return res.status(400).json({ error: 'Message too long' });
    }

    // Fetch contacts
    let contacts = [];
    if (Array.isArray(contactIds) && contactIds.length) {
      contacts = await ContactModel.find({ _id: { $in: contactIds }, user: req.user._id }).lean();
    } else {
      contacts = await ContactModel.find({ user: req.user._id }).lean();
    }

    if (!contacts || contacts.length === 0) {
      const alert = await AlertModel.create({
        user: req.user._id,
        latitude,
        longitude,
        message,
        contactsNotified: [],
        notifyResults: []
      });
      return res.status(200).json({ alert, notified: 0, warning: 'No emergency contacts found.' });
    }

    // Build alert message
    const locationText = isValidLatLng(latitude, longitude)
      ? `Location: https://maps.google.com/?q=${latitude},${longitude}`
      : '';
    const senderName = req.user?.name || 'Unknown User';
    const text = `🚨 SOS ALERT from ${senderName}! ${message || ''}\n${locationText}`.trim();

    const notifyResults = [];

    if (twilioClient && process.env.TWILIO_FROM_NUMBER) {
      const sendPromises = contacts.map(c => {
        const toNumber = c.phone.startsWith('+') ? c.phone : `+91${c.phone}`; // auto-fix if missing +
        const useWhatsApp = (process.env.USE_TWILIO_WHATSAPP === 'true' || process.env.USE_TWILIO_WHATSAPP === '1');

        const payload = useWhatsApp
          ? {
              body: text,
              from: `whatsapp:${process.env.TWILIO_FROM_NUMBER}`,
              to: `whatsapp:${toNumber}`
            }
          : {
              body: text,
              from: process.env.TWILIO_FROM_NUMBER,
              to: toNumber
            };

        return twilioClient.messages
          .create(payload)
          .then(msg => ({ phone: toNumber, success: true, sid: msg.sid }))
          .catch(err => ({
            phone: toNumber,
            success: false,
            error: err.message || String(err)
          }));
      });

      const results = await Promise.allSettled(sendPromises);

      for (const r of results) {
        if (r.status === 'fulfilled') {
          notifyResults.push(r.value);
          if (!r.value.success) console.warn('❌ Twilio send failed:', r.value.phone, r.value.error);
          else console.log('✅ SMS sent to:', r.value.phone);
        } else {
          notifyResults.push({
            phone: 'unknown',
            success: false,
            error: r.reason?.message || 'unknown error'
          });
        }
      }
    } else {
      console.log('⚙️ Twilio disabled or not configured. Simulating SMS...');
      for (const c of contacts) {
        console.log(`🧾 [SIMULATED] SMS to ${c.phone}: ${text}`);
        notifyResults.push({ phone: c.phone, success: false, error: 'twilio-disabled' });
      }
    }

    // Save alert in DB
    const alertDoc = await AlertModel.create({
      user: req.user._id,
      latitude,
      longitude,
      message,
      contactsNotified: contacts.map(c => c._id),
      notifyResults
    });

    const notifiedCount = notifyResults.filter(r => r.success).length;
    res.status(201).json({
      alert: alertDoc,
      notified: notifiedCount,
      results: notifyResults
    });
  } catch (err) {
    console.error('❌ Alert creation error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Fetch alerts (GET /api/alerts)
router.get('/', auth, async (req, res) => {
  try {
    const alerts = await AlertModel.find({ user: req.user._id })
      .populate('contactsNotified')
      .sort({ createdAt: -1 });
    res.json(alerts);
  } catch (err) {
    console.error('❌ Error fetching alerts:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
