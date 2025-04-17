#!/bin/bash

# Install dependencies (just in case)
pip install -r requirements.txt

# Run the Streamlit app
streamlit run app.py --server.port $PORT --server.address 0.0.0.0