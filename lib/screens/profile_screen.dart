import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tfg_auction/db/db_usuario.dart';
import 'package:tfg_auction/models/usuario.dart';
import 'package:tfg_auction/screens/home_screen.dart';
import 'package:tfg_auction/screens/my_products_screen.dart';
import 'package:tfg_auction/screens/request_login_screen.dart';
import 'package:tfg_auction/auth.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Usuario usuario = Usuario();
  bool _isThereChanges = false;
  bool _loading = true;

  // text editing controllers
  File _image = File('');

  final TextEditingController _nombreUsuarioController =
      TextEditingController();

  final TextEditingController _nombreCompletoController =
      TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  void checkChanges() {
    if (_nombreUsuarioController.text != usuario.nombreUsuario ||
        _nombreCompletoController.text != usuario.nombreCompleto ||
        _emailController.text != usuario.email ||
        _image.path != '') {
      setState(() {
        _isThereChanges = true;
      });
    } else {
      setState(() {
        _isThereChanges = false;
      });
    }
  }

  void cargarDatos() async {
    if (Auth().currentUser != null) {
      var sesion = await DBUsuario().read((Auth().currentUser as User).email!);
      usuario = sesion;
      _nombreUsuarioController.text = usuario.nombreUsuario!;
      _nombreCompletoController.text = usuario.nombreCompleto!;
      _emailController.text = usuario.email!;
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return usuario.email == null
        ? RequestLoginScreen()
        : _buildLoggedInScreen();
  }

  Widget _buildLoggedInScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: ListView(
        children: _buildFormProfile(),
      ),
    );
  }

  List<Widget> _buildFormProfile() {
    return [
      ZoomIn(
        child: Container(
          width: 128.0,
          height: 128.0,
          margin: const EdgeInsets.only(
            top: 24.0,
            bottom: 64.0,
          ),
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: InkWell(
              onTap: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'png', 'jpeg'],
                );
                if (result != null) {
                  setState(() {
                    _image = File(result.files.single.path!);
                  });
                }
                checkChanges();
              },
              child: FutureBuilder(
                future: getUserImage(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data as Widget;
                  } else {
                    return const Icon(Icons.account_circle_rounded,
                        color: Colors.white, size: 128.0);
                  }
                },
              )),
        ),
      ),
      FadeInRight(
        child: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
              onPressed: () async {
                await Auth().signOut();
                Get.offAll(() => HomeScreen());
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                primary: Colors.red,
                fixedSize: const Size(50, 50),
              ),
              child: const Icon(Icons.logout)),
        ),
      ),
      const SizedBox(height: 20),
      FadeInLeft(
          child: ElevatedButton(
        onPressed: () => Get.to(() => MyProductsScreen(
              usuario: usuario,
            )),
        child: const Text('Mis productos'),
      )),
      const SizedBox(height: 20),
      FadeInLeft(
        child: TextFormField(
          decoration: const InputDecoration(
            labelText: 'Nombre de usuario',
            hintText: 'Nombre de usuario',
          ),
          controller: _nombreUsuarioController,
          onChanged: (value) {
            checkChanges();
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, introduzca un nombre de usuario';
            }
            return null;
          },
        ),
      ),
      const SizedBox(height: 20),
      FadeInLeft(
        child: TextFormField(
          decoration: const InputDecoration(
            labelText: 'Nombre completo',
            hintText: 'Nombre completo',
          ),
          controller: _nombreCompletoController,
          onChanged: (value) {
            checkChanges();
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, introduzca un nombre';
            }
            return null;
          },
        ),
      ),
      const SizedBox(height: 20),
      FadeInLeft(
        child: TextFormField(
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Email',
          ),
          controller: _emailController,
          onChanged: (value) {
            checkChanges();
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, introduzca un email';
            }
            return null;
          },
        ),
      ),
      const SizedBox(height: 20),
      if (_isThereChanges)
        FadeIn(
          child: ElevatedButton(
            onPressed: () async {
              if (usuario.email != _emailController.text) {
                await Auth().updateEmail(email: _emailController.text);
              }
              usuario.nombreUsuario = _nombreUsuarioController.text;
              usuario.nombreCompleto = _nombreCompletoController.text;
              usuario.email = _emailController.text;
              await DBUsuario().save(usuario, _image);
              setState(() {
                _isThereChanges = false;
              });
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              fixedSize: const Size(200, 50),
            ),
            child: const Text('Guardar', style: TextStyle(fontSize: 20)),
          ),
        )
    ];
  }

  Future<Widget> getUserImage() async {
    if (_image.path == '') {
      try {
        String url = "";
        url = await DBUsuario().getImage(usuario);
        return Image.network(
          url,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.account_circle_rounded,
                color: Colors.white, size: 128.0);
          },
        );
      } catch (e) {
        return const Icon(Icons.account_circle_rounded,
            color: Colors.white, size: 128.0);
      }
    } else {
      return Image.file(_image);
    }
  }
}
