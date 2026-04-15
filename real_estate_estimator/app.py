import sys
import subprocess
import importlib.util

def install_and_import(package_name, import_name=None):
    if import_name is None:
        import_name = package_name
    spec = importlib.util.find_spec(import_name)
    if spec is None:
        print(f"Installing missing library: {package_name}...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", package_name])

# Automatically install required packages for both app.py and scraper.py
required_packages = {
    'streamlit': 'streamlit',
    'pandas': 'pandas',
    'numpy': 'numpy',
    'scikit-learn': 'sklearn',
    'requests': 'requests',
    'beautifulsoup4': 'bs4'
}

for pkg, imp in required_packages.items():
    install_and_import(pkg, imp)

# Now proceed with standard imports
import streamlit as st
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import OneHotEncoder
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
import time

from scraper import fetch_live_listings

st.set_page_config(page_title="Live Quetta Real Estate", layout="wide")

st.title("🏡 Live Quetta Real Estate Price Estimator")
st.markdown("This application fetches **live data** from Zameen.com to instantly train an AI model on today's real market prices!")

# Session state to hold our data and model
if 'df' not in st.session_state:
    st.session_state.df = None
if 'model' not in st.session_state:
    st.session_state.model = None
if 'last_fetch' not in st.session_state:
    st.session_state.last_fetch = None

def fetch_and_train(num_pages=5):
    with st.spinner(f"Fetching {num_pages} pages of live listings from Zameen.com..."):
        df = fetch_live_listings(num_pages)
        if df.empty:
            st.error("Failed to fetch data! Please try again later.")
            return

    with st.spinner("Training AI model on live data..."):
        # We will use 'Location_Base' and 'Size (Marla)' as features
        X = df[['Location_Base', 'Size (Marla)']]
        y = df['Price (PKR)']
        
        # Build a robust pipeline
        categorical_features = ['Location_Base']
        categorical_transformer = OneHotEncoder(handle_unknown='ignore')
        
        preprocessor = ColumnTransformer(
            transformers=[
                ('cat', categorical_transformer, categorical_features)
            ], remainder='passthrough')
            
        model = Pipeline(steps=[
            ('preprocessor', preprocessor),
            ('regressor', RandomForestRegressor(n_estimators=100, random_state=42))
        ])
        
        model.fit(X, y)
        
        st.session_state.df = df
        st.session_state.model = model
        st.session_state.last_fetch = time.strftime("%Y-%m-%d %H:%M:%S")

st.sidebar.header("Market Data Control")
num_pages = st.sidebar.slider("Pages to Scrape (more pages = better accuracy but takes longer)", min_value=1, max_value=20, value=5)

if st.sidebar.button("Fetch Live Data Now", type="primary") or st.session_state.df is None:
    fetch_and_train(num_pages)

if st.session_state.df is not None:
    st.sidebar.success(f"Model trained successfully!\\nLast fetch: {st.session_state.last_fetch}")
    
    df = st.session_state.df
    model = st.session_state.model
    
    # Get unique locations for the dropdown, ordered alphabetically
    locations = sorted(df['Location_Base'].unique())
    
    col1, col2 = st.columns([1, 1.5])
    
    with col1:
        st.subheader("Estimate Plot Price")
        st.markdown("Use the controls below to estimate the price of a plot based on the scraped live data.")
        input_location = st.selectbox("Select Location", locations)
        input_size_marla = st.number_input("Enter Size (in Marla)", min_value=0.5, max_value=200.0, value=5.0, step=0.5)
        
        # Quick conversion reference
        st.caption("Tip: 1 Kanal = 20 Marla")
        
        if st.button("Predict Price", type="secondary"):
            # Create input dataframe
            input_df = pd.DataFrame({
                'Location_Base': [input_location],
                'Size (Marla)': [input_size_marla]
            })
            
            prediction = model.predict(input_df)[0]
            
            # Format prediction
            if prediction >= 10000000:
                price_str = f"Rs {prediction / 10000000:.2f} Crore"
            elif prediction >= 100000:
                price_str = f"Rs {prediction / 100000:.2f} Lakh"
            else:
                price_str = f"Rs {prediction:,.0f}"
                
            st.success(f"### Estimated Price: {price_str}")
            
    with col2:
        st.subheader("Live Market Data Viewer")
        st.markdown(f"**Total live listings currently loaded**: {len(df)}")
        st.dataframe(df[['Raw_Location', 'Raw_Size', 'Raw_Price', 'Price (PKR)']], height=300, width='stretch')

if __name__ == '__main__':
    import sys
    from streamlit.web import cli as stcli
    import streamlit.runtime as st_runtime
    
    # Allows running this script directly without explicitly calling 'streamlit run'
    if not st_runtime.exists():
        sys.argv = ["streamlit", "run", sys.argv[0]]
        sys.exit(stcli.main())
