const { Schema, model } = require('mongoose');

const contactSchema = new Schema({
  user: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  phone: { type: String, required: true },
  relation: { type: String }
}, { timestamps: true });

module.exports = model('Contact', contactSchema);
