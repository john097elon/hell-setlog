import ast
for f in ["backend/auth.py", "backend/schemas.py"]:
  with open(f) as fh:
    ast.parse(fh.read())
  print(f + ": syntax OK")
