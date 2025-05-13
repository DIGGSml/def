# Save this as test_saxon.py
import saxonc
import os

# Print environment variables for debugging
print(f"SAXON_HOME: {os.environ.get('SAXON_HOME', 'Not set')}")
print(f"LD_LIBRARY_PATH: {os.environ.get('LD_LIBRARY_PATH', 'Not set')}")

# Try to create a Saxon processor
try:
    proc = saxonc.PySaxonProcessor(license=False)
    print(f"Saxon processor created successfully. Version: {proc.version}")
    proc.release()
except Exception as e:
    print(f"Error creating Saxon processor: {str(e)}")