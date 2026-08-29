const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuración de Middlewares
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname)));

// Configuración de la Base de Datos SQLite
const db = new sqlite3.Database('./sistema.sqlite', (err) => {
    if (err) {
        console.error('Error al conectar con la base de datos:', err.message);
    } else {
        console.log('Conectado a la base de datos SQLite.');
        // Genera la tabla automáticamente si no existe
        db.run(`CREATE TABLE IF NOT EXISTS registros (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario TEXT NOT NULL,
            accion TEXT NOT NULL,
            fecha DATETIME DEFAULT CURRENT_TIMESTAMP
        )`);
    }
});

// Ruta para cargar la interfaz principal
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// API: Obtener todos los datos de la base
app.get('/api/registros', (req, res) => {
    db.all('SELECT * FROM registros ORDER BY fecha DESC', [], (err, rows) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json({ data: rows });
    });
});

// API: Insertar un nuevo dato
app.post('/api/registros', (req, res) => {
    const { usuario, accion } = req.body;
    
    if (!usuario || !accion) {
        res.status(400).json({ error: 'Todos los campos son requeridos' });
        return;
    }
    
    const sql = 'INSERT INTO registros (usuario, accion) VALUES (?, ?)';
    db.run(sql, [usuario, accion], function(err) {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json({ message: 'Guardado exitosamente', id: this.lastID });
    });
});

// Iniciar servidor
app.listen(PORT, () => {
    console.log(`Servidor activo en http://localhost:${PORT}`);
});
