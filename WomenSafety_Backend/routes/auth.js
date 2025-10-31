const express = require('express');
const router = express.Router();
const User = require('../models/User');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// Register
router.post('/register', async (req,res) => {
  try{
    const { name, email, password, phone } = req.body;
    if(!name || !email || !password) return res.status(400).json({ error: 'name,email,password required' });
    const exists = await User.findOne({ email });
    if(exists) return res.status(400).json({ error: 'email already registered' });
    const hash = await bcrypt.hash(password, 10);
    const user = await User.create({ name, email, passwordHash: hash, phone });
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '30d' });
    res.json({ user: { id: user._id, name: user.name, email: user.email, phone: user.phone }, token });
  }catch(err){ console.error(err); res.status(500).json({ error: 'server error' }); }
});

// Login
router.post('/login', async (req,res) => {
  try{
    const { email, password } = req.body;
    if(!email || !password) return res.status(400).json({ error: 'email,password required' });
    const user = await User.findOne({ email });
    if(!user) return res.status(400).json({ error: 'invalid credentials' });
    const ok = await user.verifyPassword(password);
    if(!ok) return res.status(400).json({ error: 'invalid credentials' });
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '30d' });
    res.json({ user: { id: user._id, name: user.name, email: user.email, phone: user.phone }, token });
  }catch(err){ console.error(err); res.status(500).json({ error: 'server error' }); }
});

module.exports = router;
