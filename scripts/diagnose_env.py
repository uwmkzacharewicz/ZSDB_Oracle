import sys
import site

print(">>> sys.executable")
print(sys.executable)

print("\n>>> sys.version")
print(sys.version)

print("\n>>> sys.path")
for p in sys.path:
    print("  ", p)

print("\n>>> site.getsitepackages()")
for p in site.getsitepackages():
    print("  ", p)

print("\n>>> site.getusersitepackages()")
print(site.getusersitepackages())
