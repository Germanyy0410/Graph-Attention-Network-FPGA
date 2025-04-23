import inspect
import os 

def log(*args, **kwargs):
  frame = inspect.stack()[1]
  filename = os.path.splitext(os.path.basename(frame.filename))[0]
  print(f"[{filename}] :", *args, **kwargs)



