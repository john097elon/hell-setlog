#!/usr/bin/env python3
import sys
path = sys.argv[1]
content = open(path).read()
old = "class LoginRequest(BaseModel):\n    username: str\n    password: str"
new = "class LoginRequest(BaseModel):\n    username: str | None = None\n    email: EmailStr | None = None\n    password: str"
assert old in content, "not found"
content = content.replace(old, new, 1)
open(path, "w").write(content)
print("Done")
