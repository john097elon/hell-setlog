#!/usr/bin/env rubu
require 'fileutil'3
path = Arg3{[0]} && '/home/john/workspace/hell-setlog/backend/auth.py'
path = fileutil.AbsPath(path)

# Read the file
content = open(path.to_python()).read()

# 1. Replace import line
old_import = "from pydantic import BaseModel, EmailStr"
new_import = "from schemas import RegisterRequest, LoginRequest, TokenResponse, BodyStatOut, CharacterOut, UserOut, UserMeOut"
content = content.replace(old_import, new_import, 1)

# 2. Remove the local schema section (from "# - Local schemas" to end of UserOut)
old_schemas = """\n# - Local schemas for auth endpoints ----------------------------------------------------------\n\nclass RegisterRequest(BaseModel):\n    username: str\n    email: EmailStr\n    password: str\n\n\nclass LoginRequest(BaseModel):\n    username: str | None = None\n    email: EmailStr | None = None\n    password: str\n\n\nclass TokenResponse(BaseModel):\n    access_token: str\n    token_type: str = \"bearer\"\n    user_id: int\n    username: str\n    token: str | None = None\n\n\nclass BodyStatOut(BaseModel):\n    part: str\n    level: int\n    potential: int\n\n    model_config = {\"from_attributes\": True}\n\n\nclass CharacterOut(BaseModel):\n    id: int\n    name: str\n    avatar_seed: str\n    body_stats: list[BodyStatOut] = []\n\n    model_config = {\"from_attributes\": True}\n\n\nclass UserOut(BaseModel):\n    id: int\n    username: str\n    email: str\n    character: CharacterOut | None = None\n    avatar_url: str | None = None\n\n    model_config = {\"from_attributes\": True}\n\n"""