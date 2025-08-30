#!/bin/bash

echo "��� Setting up Gate Pass Flutter App..."

# Create directories
echo "��� Creating directories..."
mkdir -p lib/models
mkdir -p lib/providers  
mkdir -p lib/screens/auth
mkdir -p lib/screens/student
mkdir -p lib/screens/teacher
mkdir -p lib/screens/admin
mkdir -p lib/screens/security
mkdir -p lib/services
mkdir -p lib/utils
mkdir -p lib/widgets
mkdir -p assets/{images,icons,fonts}

# Create all Dart files
echo "��� Creating Dart files..."
touch lib/main.dart
touch lib/models/{user_model.dart,gate_pass_model.dart}
touch lib/providers/{auth_provider.dart,gate_pass_provider.dart}
touch lib/screens/splash_screen.dart
touch lib/screens/auth/{login_screen.dart,register_screen.dart}
touch lib/screens/student/student_dashboard.dart
touch lib/screens/teacher/teacher_dashboard.dart
touch lib/screens/admin/admin_dashboard.dart
touch lib/screens/security/security_dashboard.dart
touch lib/services/api_service.dart
touch lib/utils/theme.dart
touch lib/widgets/{custom_button.dart,custom_text_field.dart}
touch README.md

echo "File structure created!"
echo "��� Now copy the content from each artifact into the corresponding files."
echo "��� Don't forget to replace pubspec.yaml and AndroidManifest.xml content!"
