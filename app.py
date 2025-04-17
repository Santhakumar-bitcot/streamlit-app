import streamlit as st
import pandas as pd
import numpy as np

st.title("📊 Streamlit App on Azure")

st.sidebar.header("User Input")
num_points = st.sidebar.slider("Number of data points", 10, 100, 50)

data = pd.DataFrame({
    'x': np.random.rand(num_points),
    'y': np.random.rand(num_points)
})

st.subheader("Generated Data")
st.write(data)

st.subheader("Scatter Plot")
st.scatter_chart(data)
