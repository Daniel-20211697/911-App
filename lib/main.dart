
//Daniel Baez 2021-1697
import 'dart:io'; 
import 'package:flutter/material.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:path/path.dart'; 
import 'package:sqflite/sqflite.dart'; 

void main() {
  runApp(MiApp());
}

class MiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App 911',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PaginaInicio(),
    );
  }
}

class PaginaInicio extends StatefulWidget {
  @override
  _PaginaInicioState createState() => _PaginaInicioState();
}

class _PaginaInicioState extends State<PaginaInicio> {
  late Database _baseDatos; // Base de datos SQLite.
  List<Map<String, dynamic>>? _eventos; // Lista de eventos cargados desde la base de datos.

  @override
  void initState() {
    super.initState();
    _inicializarBaseDatos(); // Inicializa la base de datos al iniciar la aplicación.
  }

  Future<void> _inicializarBaseDatos() async {
    Directory directorioDocumentos = await getApplicationDocumentsDirectory();
    String ruta = join(directorioDocumentos.path, '911.db');
    _baseDatos = await openDatabase(ruta, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
          CREATE TABLE Eventos(
            id INTEGER PRIMARY KEY,
            titulo TEXT,
            descripcion TEXT,
            fecha TEXT,
            foto TEXT
          )
        ''');
    });
    _refrescarEventos(); // Carga los eventos desde la base de datos.
  }

  Future<void> _refrescarEventos() async {
    final List<Map<String, dynamic>> eventos = await _baseDatos.query('Eventos');
    setState(() {
      _eventos = eventos; // Actualiza la lista de eventos.
    });
  }

  Future<void> _agregarEvento(String titulo, String descripcion, String fecha,
      String fotoRuta) async {
    await _baseDatos.insert('Eventos', {
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha': fecha,
      'foto': fotoRuta
    });
    _refrescarEventos(); // Agrega un nuevo evento a la base de datos.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App 911'), // Título de la barra de navegación.
      ),
      body: _eventos == null ? _indicadorCarga() : _listaEventos(), // Cuerpo de la página.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaginaAgregarEvento(onEventoAgregado: _agregarEvento),
            ),
          );
        },
        child: Icon(Icons.add), // Botón flotante para agregar un nuevo evento.
      ),
    );
  }

  Widget _indicadorCarga() {
    return Center(
      child: CircularProgressIndicator(), // Indicador de carga mientras se cargan los eventos.
    );
  }

  Widget _listaEventos() {
    return ListView.builder(
      itemCount: _eventos!.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(_eventos![index]['titulo'] ?? ''),
          subtitle: Text(_eventos![index]['fecha'] ?? ''),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaginaDetallesEvento(evento: _eventos![index]),
              ),
            );
          },
        );
      },
    );
  }
}

class PaginaAgregarEvento extends StatefulWidget {
  final Function(String, String, String, String) onEventoAgregado;

  const PaginaAgregarEvento({Key? key, required this.onEventoAgregado}) : super(key: key);

  @override
  _PaginaAgregarEventoState createState() => _PaginaAgregarEventoState();
}
//Daniel Baez 2021-1697
class _PaginaAgregarEventoState extends State<PaginaAgregarEvento> {
  late TextEditingController _controladorTitulo;
  late TextEditingController _controladorDescripcion;
  late TextEditingController _controladorFecha;
  String _rutaFoto = '';

  @override
  void initState() {
    super.initState();
    _controladorTitulo = TextEditingController();
    _controladorDescripcion = TextEditingController();
    _controladorFecha = TextEditingController(text: DateTime.now().toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Evento'), // Título de la página de agregar evento.
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controladorTitulo,
              decoration: InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _controladorDescripcion,
              decoration: InputDecoration(labelText: 'Descripción'),
            ),
            TextField(
              controller: _controladorFecha,
              decoration: InputDecoration(labelText: 'Fecha'),
              readOnly: true,
              onTap: () async {
                DateTime? fechaSeleccionada = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (fechaSeleccionada != null) {
                  TimeOfDay? horaSeleccionada = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (horaSeleccionada != null) {
                    setState(() {
                      _controladorFecha.text = DateTime(
                        fechaSeleccionada.year,
                        fechaSeleccionada.month,
                        fechaSeleccionada.day,
                        horaSeleccionada.hour,
                        horaSeleccionada.minute,
                      ).toString();
                    });
                  }
                }
              },
            ),
            ElevatedButton(
              onPressed: () {
                _tomarFoto(ImageSource.camera); // Abre la cámara para tomar una foto.
              },
              child: Text('Tomar Foto'),
            ),
            ElevatedButton(
              onPressed: () {
                _tomarFoto(ImageSource.gallery); // Abre la galería para seleccionar una foto.
              },
              child: Text('Seleccionar desde Galería'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                widget.onEventoAgregado(
                  _controladorTitulo.text,
                  _controladorDescripcion.text,
                  _controladorFecha.text,
                  _rutaFoto,
                );
                Navigator.pop(context);
              },
              child: Text('Agregar Evento'), // Botón para agregar un nuevo evento.
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tomarFoto(ImageSource origen) async {
    final picker = ImagePicker();
    final archivoImagen = await picker.pickImage(source: origen);

    if (archivoImagen != null) {
      setState(() {
        _rutaFoto = archivoImagen.path!;
      });
    }
  }

  @override
  void dispose() {
    _controladorTitulo.dispose();
    _controladorDescripcion.dispose();
    _controladorFecha.dispose();
    super.dispose();
  }
}

class PaginaDetallesEvento extends StatelessWidget {
  final Map<String, dynamic> evento;

  const PaginaDetallesEvento({Key? key, required this.evento}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Evento'), // Título de la página de detalles del evento.
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              evento['titulo'] ?? '',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Fecha: ${evento['fecha'] ?? ''}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Descripción: ${evento['descripcion'] ?? ''}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            if (evento['foto'] != null)
              Image.file(
                File(evento['foto']),
                height: 200,
              ), // Muestra la foto asociada al evento.
          ],
        ),
      ),
    );
  }
}
//Daniel Baez 2021-1697