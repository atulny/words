import sqlalchemy
from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy import create_engine, Column, Integer, String, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship, Session
from sqlalchemy.future import select
from databases import Database
import jwt
from datetime import datetime, timedelta
from passlib.context import CryptContext

DATABASE_URL = "sqlite:///./word_memorizer.db"

database = Database(DATABASE_URL)
metadata = sqlalchemy.MetaData()

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

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

# Define SQLAlchemy models
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)

class Word(Base):
    __tablename__ = "words"
    id = Column(Integer, primary_key=True, index=True)
    word = Column(String, index=True)
    order = Column(Integer)
    user_id = Column(Integer, ForeignKey("users.id"))

Base.metadata.create_all(bind=engine)

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class Token(BaseModel):
    access_token: str
    token_type: str
class UserModel(BaseModel):
    id: Optional[int]=None
    username: str
    password: Optional[str]
class WordModel(BaseModel):
    id: Optional[int]=None
    word: str
    order : Optional[int]=None
    user_id : Optional[int]=None

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def authenticate_user(username: str, password: str):
    user_db = SessionLocal()
    user = user_db.query(User).filter(User.username == username).first()
    user_db.close()

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
    user_db = SessionLocal()
    user = user_db.query(User).filter(User.username == username).first()
    user_db.close()
    if user is None:
        raise credentials_exception
    return user

@app.post("/register", status_code=status.HTTP_201_CREATED, response_model=None)
async def register(user: UserModel, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    hashed_password = get_password_hash(user.password)
    new_user = User(username=user.username, hashed_password=hashed_password)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"message": "User created successfully"}

@app.post("/token", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/words", response_model=None)
async def add_word(word: WordModel, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db_word = Word(word=word.word, order=word.order, user_id=current_user.id)
    db.add(db_word)
    db.commit()
    db.refresh(db_word)
    return {"message": "Word added successfully"}

@app.get("/words", response_model=List[WordModel])
async def get_words(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    words = db.query(Word).filter(Word.user_id == current_user.id).all()
    return words

@app.put("/words/reorder", response_model=None)
async def reorder_words(words: List[WordModel], current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    for word in words:
        db_word = db.query(Word).filter(Word.id == word.id, Word.user_id == current_user.id).first()
        if db_word:
            db_word.order = word.order
    db.commit()
    return {"message": "Words reordered successfully"}

@app.delete("/words/{word_id}", status_code=status.HTTP_200_OK, response_model=None)
async def delete_word(word_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db_word = db.query(Word).filter(Word.id == word_id, Word.user_id == current_user.id).first()
    if not db_word:
        raise HTTPException(status_code=404, detail="Word not found")
    db.delete(db_word)
    db.commit()
    return {"message": "Word deleted successfully"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)

