import ast
for f in ["backend/auth.py", "backend/schemas.py"]:
  with open(f, encoding="utf-8") as fh:
    ast.parse(fh.read())
  print(f + ": syntax OK")
