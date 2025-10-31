const { Schema, model } = require('mongoose');

const alertSchema = new Schema({
  user: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  latitude: { type: Number },
  longitude: { type: Number },
  message: { type: String },
  contactsNotified: [{ type: Schema.Types.ObjectId, ref: 'Contact' }]
}, { timestamps: true });

module.exports = model('Alert', alertSchema);
