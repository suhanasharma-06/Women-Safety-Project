const jwt = require('jsonwebtoken');
const UserModel = require('../models/User');

module.exports = async function(req, res, next){
  const auth = req.headers.authorization;
  if(!auth || !auth.startsWith('Bearer ')) return res.status(401).json({ error: 'Missing token' });
  
  const token = auth.split(' ')[1];
  
  try{
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const user = await UserModel.findById(payload.id);
    if(!user) return res.status(401).json({ error: 'Invalid token (user missing)' });
    req.user = user;
    next();
  }catch(err){
    return res.status(401).json({ error: 'Invalid token' });
  }
}
