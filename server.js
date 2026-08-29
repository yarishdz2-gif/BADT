require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname)));

// Tu URI de MongoDB (Puedes usar variables de entorno para mayor seguridad después)
const MONGO_URI = "mongodb+srv://yarishdz2_db_user:7cp3VZH9aXK77wX@ikgmxer.8tj7kfa.mongodb.net/hubsilent?appName=ikgmxer";

mongoose.connect(MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => {
    console.log("Conectado exitosamente a la base de datos Qyrex (hubsilent) en MongoDB");
}).catch(err => {
    console.error("Error conectando a MongoDB:", err);
});

// Esquema para leer la colección 'qrexusers'
const userSchema = new mongoose.Schema({
    username: String,
    role: { type: String, default: 'user' },
    premium: { type: Boolean, default: false },
    createdAt: { type: Date, default: Date.now }
}, { collection: 'qrexusers' });

const QrexUser = mongoose.model('QrexUser', userSchema);

// API para enviar los usuarios al HTML
app.get('/api/users', async (req, res) => {
    try {
        const users = await QrexUser.find().sort({ createdAt: -1 });
        res.json(users);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Cargar la interfaz del panel
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
    console.log(`Panel Qyrex activo en http://localhost:${PORT}`);
});
