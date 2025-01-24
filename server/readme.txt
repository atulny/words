echo "export FLUTTERPATH=\$HOME/flutter" >> ~/.zshrc
echo "export PATH=\"\$PATH:\$FLUTTERPATH/bin\"" >> ~/.zshrc
source ~/.zshrc

flutter run -d web-server --web-port 5011
flutter create .             
flutter pub get
pip install python-multipart, python-jose, uvicorn, passlib, sqlalchemy, fastapi
❯ python server/main.py