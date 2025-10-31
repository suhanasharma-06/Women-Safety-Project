const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Contact = require('../models/Contact');

// Create contact
router.post('/', auth, async (req,res) => {
  try{
    const { name, phone, relation } = req.body;
    if(!name || !phone) return res.status(400).json({ error: 'name and phone required' });
    const contact = await Contact.create({ user: req.user._id, name, phone, relation });
    res.json(contact);
  }catch(err){ console.error(err); res.status(500).json({ error: 'server error' }); }
});

// List
router.get('/', auth, async (req,res) => {
  try{
    const contacts = await Contact.find({ user: req.user._id }).sort({ createdAt: -1 });
    res.json(contacts);
  }catch(err){ console.error(err); res.status(500).json({ error: 'server error' }); }
});

// Update
router.put('/:id', auth, async (req,res) => {
  try{
    const contact = await Contact.findOneAndUpdate({ _id: req.params.id, user: req.user._id }, req.body, { new: true });
    if(!contact) return res.status(404).json({ error: 'not found' });
    res.json(contact);
  }catch(err){ console.error(err); res.status(500).json({ error: 'server error' }); }
});

// Delete
router.delete('/:id', auth, async (req,res) => {
  try{
    const contact = await Contact.findOneAndDelete({ _id: req.params.id, user: req.user._id });
    if(!contact) return res.status(404).json({ error: 'not found' });
    res.json({ success: true });
  }catch(err){ console.error(err); res.status(500).json({ error: 'server error' }); }
});

module.exports = router;
