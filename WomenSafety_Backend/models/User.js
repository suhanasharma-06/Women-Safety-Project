const { Schema, model } = require('mongoose');
const bcrypt = require('bcrypt');

const userSchema = new Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  passwordHash: { type: String, required: true },
  phone: { type: String }
}, { timestamps: true });

userSchema.methods.verifyPassword = async function(password) {
  return bcrypt.compare(password, this.passwordHash);
}

module.exports = model('User', userSchema);
