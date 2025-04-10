import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class Ex4 extends StatefulWidget {
  const Ex4({super.key});

  @override
  State<Ex4> createState() => _Ex4State();
}

class _Ex4State extends State<Ex4> {
  int _currentStep = 0;
  bool _isCompleted = false;

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  String _firstName = '';
  String _lastName = '';
  String _address = '';
  String _postalCode = '';

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Personal'),
        content: Form(
          key: _formKeyStep1,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter first name';
                  }
                  return null;
                },
                onSaved: (value) => _firstName = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter last name';
                  }
                  return null;
                },
                onSaved: (value) => _lastName = value ?? '',
              ),
            ],
          ),
        ),
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 0,
      ),
      Step(
        title: const Text('Shipping'),
        content: Form(
          key: _formKeyStep2, 
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Shipping Address',
                  prefixIcon: Icon(Icons.home_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter shipping address';
                  }
                  return null;
                },
                onSaved: (value) => _address = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Postal code',
                  prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number, 

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter postal code';
                  }
                  return null;
                },
                onSaved: (value) => _postalCode = value ?? '',
              ),
            ],
          ),
        ),
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 1,
      ),
      Step(
        title: const Text('Confirm'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('First Name: $_firstName'),
            Text('Last Name: $_lastName'),
            Text('Address: $_address'),
            Text('Postal Code: $_postalCode'),
          ],
        ),
        state: _currentStep >= 2 ? StepState.complete : StepState.indexed, 
        isActive: _currentStep >= 2,
      ),
    ];
  }

  void _onStepContinue() {
    bool isLastStep = _currentStep == _buildSteps().length - 1;

    if (_currentStep == 0) {
      if (_formKeyStep1.currentState!.validate()) {
        _formKeyStep1.currentState!.save(); 
        setState(() {
          _currentStep += 1;
        });
      }
    } else if (_currentStep == 1) {
      if (_formKeyStep2.currentState!.validate()) {
        _formKeyStep2.currentState!.save(); 
        setState(() {
          _currentStep += 1;
        });
      }
    } else if (isLastStep) {
      setState(() {
        _isCompleted = true; 
      });
      print('Form Submitted!');
      print('First Name: $_firstName');
      print('Last Name: $_lastName');
      print('Address: $_address');
      print('Postal Code: $_postalCode');
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  void _onStepTapped(int step) {
     setState(() {
       _currentStep = step;
     });

  }

  void _resetStepper() {
    setState(() {
      _currentStep = 0;
      _isCompleted = false;
      _firstName = '';
      _lastName = '';
      _address = '';
      _postalCode = '';
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Multi-Step Form'),
    ),
    body: _isCompleted
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Thank You!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _resetStepper,
                  child: const Text('RESET'),
                ),
              ],
            ),
          )
        : Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            steps: _buildSteps(),
            onStepTapped: _onStepTapped,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            controlsBuilder: (BuildContext context, ControlsDetails details) {
              final bool isLastStep = details.stepIndex == _buildSteps().length - 1;
              return Container(
                margin: const EdgeInsets.only(top: 24.0), 
                padding: const EdgeInsets.symmetric(horizontal: 16.0), 
                child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: <Widget>[
                    if (details.stepIndex > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),


                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: isLastStep
                          ? ElevatedButton.styleFrom(backgroundColor: Colors.green)
                          : null,
                      child: Text(isLastStep ? 'Finish' : 'Next'),
                    ),
                  ],
                ),
              );
            },
          ),
  );
}
}
