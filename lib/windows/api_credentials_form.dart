/// Provides the ApiCredentialsForm] class.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';

class ApiCredentialsForm extends StatefulWidget {
  const ApiCredentialsForm(this._callback) : super();

  final Function() _callback;

  @override
  ApiCredentialsFormState createState() => ApiCredentialsFormState(_callback);

  static Widget explanation(BuildContext context, Function() cb) {
    return ListView(
      children: <Widget>[
        const Text('No API credentials have been entered.'),
        const Text(
            'Click the button below to enter the credentials for your Transport API application.'),
        ElevatedButton(
            child: const Text('API Credentials'),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<ApiCredentialsForm>(
                    builder: (BuildContext context) => ApiCredentialsForm(cb))))
      ],
    );
  }
}

class ApiCredentialsFormState extends State<ApiCredentialsForm> {
  ApiCredentialsFormState(this._callback) : super();

  final Function() _callback;

  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  TextEditingController _appIdController;
  TextEditingController _appKeyController;

  @override
  void initState() {
    super.initState();
    _appIdController = TextEditingController(text: credentials.appId ?? '');
    _appKeyController = TextEditingController(text: credentials.appKey ?? '');
  }

  @override
  Widget build(BuildContext context) {
    String textValidator(String value) {
      if (value.isEmpty) {
        return 'You must enter a value.';
      }
      return null;
    }

    final Form form = Form(
      key: _key,
      child: ListView(
        children: <Widget>[
          TextFormField(
            controller: _appIdController,
            decoration: const InputDecoration(hintText: 'App ID'),
            validator: textValidator,
          ),
          TextFormField(
              controller: _appKeyController,
              decoration: const InputDecoration(hintText: 'App Key'),
              validator: textValidator)
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
          title: const Text('API Credentials'),
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Visit TransportAPI'),
              onPressed: () => launch(
                  'https://developer.transportapi.com/admin/applications'),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save',
              onPressed: () {
                if (_key.currentState.validate()) {
                  Navigator.of(context).pop();
                  credentials.appId = _appIdController.text;
                  credentials.appKey = _appKeyController.text;
                  saveCredentials();
                  _callback();
                }
              },
            )
          ]),
      body: form,
    );
  }

  Future<void> saveCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('appId', credentials.appId);
    prefs.setString('appKey', credentials.appKey);
  }

  @override
  void dispose() {
    super.dispose();
    _appIdController.dispose();
    _appKeyController.dispose();
  }
}
