import 'package:dementia_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter/material.dart';
import 'login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<StatefulWidget> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool notVisiblePassword = true;
  Icon passwordIcon = const Icon(Icons.visibility);

  // Controllers for text fields
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var firstNameController = TextEditingController();
  var lastNameController = TextEditingController();
  var dobController = TextEditingController();
  String gender = "Select Gender";

  // Function to toggle password visibility
  void passwordVisibility() {
    setState(() {
      if (notVisiblePassword) {
        passwordIcon = const Icon(Icons.visibility);
      } else {
        passwordIcon = const Icon(Icons.visibility_off);
      }
      notVisiblePassword = !notVisiblePassword;
    });
  }

  // SignUp logic
  void signUp() async {
    String email = emailController.text;
    String password = passwordController.text;
    String firstName = firstNameController.text;
    String lastName = lastNameController.text;
    String dob = dobController.text;
    String gender = this.gender;

    AuthRepositoryImpl authRepository = AuthRepositoryImpl();

    try {
      await authRepository.signUpWithEmail(
        email,
        password,
        firstName,
        lastName,
        dob,
        gender,
      );

      // Navigate to LoginPage after successful sign-up
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginPage()));
    } catch (e) {
      // Handle errors
      print("Error signing up: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 40),
            SizedBox(
              height: size.height / 3,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Image.asset('assets/images/signup.jpg'),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Register',
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Form(
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            icon: Icon(Icons.alternate_email_outlined),
                            labelText: 'Email ID',
                          ),
                          controller: emailController,
                        ),
                        TextFormField(
                          obscureText: notVisiblePassword,
                          decoration: InputDecoration(
                            icon: const Icon(Icons.lock_outline_rounded),
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              onPressed: passwordVisibility,
                              icon: passwordIcon,
                            ),
                          ),
                          controller: passwordController,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            icon: Icon(Icons.person),
                            labelText: 'First Name',
                          ),
                          controller: firstNameController,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            icon: Icon(Icons.person),
                            labelText: 'Last Name',
                          ),
                          controller: lastNameController,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            icon: Icon(Icons.calendar_today),
                            labelText: 'Date of Birth',
                          ),
                          controller: dobController,
                          readOnly: true,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                dobController.text =
                                    pickedDate.toString().split(" ")[0];
                              });
                            }
                          },
                        ),
                        DropdownButtonFormField<String>(
                          value: gender,
                          onChanged: (newValue) {
                            setState(() {
                              gender = newValue!;
                            });
                          },
                          items: ["Select Gender", "Male", "Female", "Other"]
                              .map((gender) => DropdownMenuItem(
                                  value: gender, child: Text(gender)))
                              .toList(),
                          decoration: const InputDecoration(
                            icon: Icon(Icons.accessibility),
                            labelText: 'Gender',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  ElevatedButton(
                    onPressed: signUp,
                    child: const Text("Sign Up"),
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey),
                        ),
                        GestureDetector(
                          child: const Text(
                            "Login",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo),
                          ),
                          onTap: () {
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (context) {
                              return LoginPage();
                            }));
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
