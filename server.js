require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'super_clave_secreta_ikgo_2026';

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname)));

const MONGO_URI = "mongodb+srv://yarishdz2_db_user:7cp3VZH9aXK77wX@ikgmxer.8tj7kfa.mongodb.net/hubsilent?appName=ikgmxer";

mongoose.connect(MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
    .then(() => console.log("Conectado a MongoDB Atlas (hubsilent)"))
    .catch(err => console.error("Error MongoDB:", err));

// --- ESQUEMAS DE BASE DE DATOS ---

// 1. Colección para los Administradores del Panel
const panelAdminSchema = new mongoose.Schema({
    username: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    role: { type: String, default: 'admin' } // 'owner' o 'admin'
});
const PanelAdmin = mongoose.model('PanelAdmin', panelAdminSchema);

// 2. Colección de Usuarios de tu Hub (qrexusers)
const userSchema = new mongoose.Schema({
    username: String,
    password: String, // Aunque se recomienda encriptar, aquí lo leerá si existe
    role: String,
    premium: Boolean,
    createdAt: { type: Date, default: Date.now }
}, { collection: 'qrexusers' });
const AppUser = mongoose.model('AppUser', userSchema);

// 3. Colección de Scripts (qrexscripts)
const scriptSchema = new mongoose.Schema({
    name: String,
    scriptData: String,
    createdAt: { type: Date, default: Date.now }
}, { collection: 'qrexscripts' });
const AppScript = mongoose.model('AppScript', scriptSchema);


// --- MIDDLEWARE DE AUTENTICACIÓN ---
const verificarToken = (req, res, next) => {
    const token = req.headers['authorization'];
    if (!token) return res.status(403).json({ error: 'No autorizado' });
    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err) return res.status(403).json({ error: 'Token inválido' });
        req.user = decoded;
        next();
    });
};

// --- RUTAS DE LOGIN Y REGISTRO DEL PANEL ---
app.post('/api/auth/register', async (req, res) => {
    try {
        const { username, password } = req.body;
        const hashedPassword = await bcrypt.hash(password, 10);
        // Si el usuario es 'owner', le damos rango máximo
        const role = username === 'owner' ? 'owner' : 'admin';
        
        const newAdmin = new PanelAdmin({ username, password: hashedPassword, role });
        await newAdmin.save();
        res.json({ message: 'Registrado exitosamente' });
    } catch (err) {
        res.status(400).json({ error: 'El usuario ya existe o hubo un error' });
    }
});

app.post('/api/auth/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        const admin = await PanelAdmin.findOne({ username });
        if (!admin) return res.status(404).json({ error: 'Usuario no encontrado' });

        const validPassword = await bcrypt.compare(password, admin.password);
        if (!validPassword) return res.status(401).json({ error: 'Contraseña incorrecta' });

        const token = jwt.sign({ id: admin._id, username: admin.username, role: admin.role }, JWT_SECRET, { expiresIn: '24h' });
        res.json({ token, role: admin.role, username: admin.username });
    } catch (err) {
        res.status(500).json({ error: 'Error en el servidor' });
    }
});

// --- RUTAS DE DATOS (PROTEGIDAS) ---
app.get('/api/data/users', verificarToken, async (req, res) => {
    const users = await AppUser.find().sort({ createdAt: -1 });
    res.json(users);
});

app.get('/api/data/scripts', verificarToken, async (req, res) => {
    const scripts = await AppScript.find().sort({ createdAt: -1 });
    res.json(scripts);
});

app.get('/api/data/admins', verificarToken, async (req, res) => {
    // Solo el 'owner' puede ver a los demás admins
    if (req.user.role !== 'owner') return res.status(403).json({ error: 'Acceso denegado' });
    const admins = await PanelAdmin.find({}, '-password'); // No enviar la contraseña
    res.json(admins);
});

// Cargar Interfaz
app.get('/', (req, res) => res.sendFile(path.join(__dirname, 'index.html')));

app.listen(PORT, () => console.log(`Servidor activo en http://localhost:${PORT}`));
