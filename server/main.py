from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import jwt
from datetime import datetime, timedelta
from passlib.context import CryptContext

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# This should be a secure random string in a real application
SECRET_KEY = "your-secret-key"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# In-memory database (replace with a real database in production)
users_db = {}
words_db = {}

class User(BaseModel):
    username: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class Word(BaseModel):
    word: str
    order: int

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def authenticate_user(username: str, password: str):
    user = users_db.get(username)
    if not user:
        return False
    if not verify_password(password, user['hashed_password']):
        return False
    return user

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except jwt.PyJWTError:
        raise credentials_exception
    user = users_db.get(username)
    if user is None:
        raise credentials_exception
    return user

@app.post("/register", status_code=status.HTTP_201_CREATED)
async def register(user: User):
    if user.username in users_db:
        raise HTTPException(status_code=400, detail="Username already registered")
    hashed_password = get_password_hash(user.password)
    users_db[user.username] = {"username": user.username, "hashed_password": hashed_password}
    words_db[user.username] = []
    return {"message": "User created successfully"}

@app.post("/token", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user['username']}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/words")
async def add_word(word: Word, current_user: User = Depends(get_current_user)):
    if current_user['username'] not in words_db:
        words_db[current_user['username']] = []
    words_db[current_user['username']].append((word.word, word.order))
    words_db[current_user['username']].sort(key=lambda x: x[1])  # Sort by order
    return {"message": "Word added successfully"}

@app.get("/words", response_model=List[Word])
async def get_words(current_user: User = Depends(get_current_user)):
    return [Word(word=w, order=o) for w, o in words_db.get(current_user['username'], [])]

@app.put("/words/reorder")
async def reorder_words(words: List[Word], current_user: User = Depends(get_current_user)):
    words_db[current_user['username']] = [(w.word, w.order) for w in words]
    words_db[current_user['username']].sort(key=lambda x: x[1])  # Sort by order
    return {"message": "Words reordered successfully"}

@app.delete("/words/{word_id}", status_code=status.HTTP_200_OK)
async def delete_word(word_id: int, current_user: User = Depends(get_current_user)):
    user_words = words_db.get(current_user['username'], [])
    updated_words = [word for word in user_words if word[1] != word_id]
    
    if len(updated_words) == len(user_words):
        raise HTTPException(status_code=404, detail="Word not found")
    
    words_db[current_user['username']] = updated_words
    return {"message": "Word deleted successfully"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)

