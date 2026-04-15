import requests
from bs4 import BeautifulSoup
import pandas as pd
import re
import time

def parse_price(price_str):
    if not price_str:
        return None
    price_str = price_str.lower().replace(',', '').strip()
    match = re.search(r'([\d.]+)\s*(lakh|crore|arab)?', price_str)
    if not match:
        return None
    
    val = float(match.group(1))
    unit = match.group(2)
    
    if unit == 'lakh':
        return val * 100000
    elif unit == 'crore':
        return val * 10000000
    elif unit == 'arab':
        return val * 1000000000
    return val

def parse_area_to_marla(area_str):
    if not area_str:
        return None
    area_str = area_str.lower().strip()
    match = re.search(r'([\d.]+)\s*(marla|kanal|sq\. yd\.|sq\. ft\.)?', area_str)
    if not match:
        return None
    
    val = float(match.group(1))
    unit = match.group(2)
    
    if unit == 'kanal':
        return val * 20
    elif unit == 'sq. yd.':
        return val / 30.25
    elif unit == 'sq. ft.':
        return val / 225.0
    
    return val  # Default to Marla

def fetch_live_listings(num_pages=5):
    data = []
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36'
    }
    
    for page in range(1, num_pages + 1):
        url = f'https://www.zameen.com/Plots/Quetta-18-{page}.html'
        try:
            r = requests.get(url, headers=headers, timeout=10)
            if r.status_code != 200:
                print(f"Failed to fetch page {page}, status: {r.status_code}")
                continue
            
            soup = BeautifulSoup(r.text, 'html.parser')
            items = soup.find_all('li', role='article')
            
            for item in items:
                try:
                    price_elem = item.find(attrs={'aria-label': 'Price'})
                    loc_elem = item.find(attrs={'aria-label': 'Location'})
                    area_elem = item.find(attrs={'aria-label': 'Area'})
                    
                    if not (price_elem and loc_elem and area_elem):
                        continue
                        
                    price_raw = price_elem.text.strip()
                    loc_raw = loc_elem.text.strip()
                    area_raw = area_elem.text.strip()
                    
                    price = parse_price(price_raw)
                    area_marla = parse_area_to_marla(area_raw)
                    
                    if price is not None and area_marla is not None:
                        data.append({
                            'Location': loc_raw,
                            'Size (Marla)': area_marla,
                            'Price (PKR)': price,
                            'Raw_Location': loc_raw,
                            'Raw_Size': area_raw,
                            'Raw_Price': price_raw
                        })
                except Exception as e:
                    pass
            
        except Exception as e:
            print(f"Error on page {page}: {e}")
            
    df = pd.DataFrame(data)
    
    # Optional cleaning: Clean up locations to standard format if needed
    if not df.empty:
        df['Location_Base'] = df['Location'].apply(lambda x: x.split(',')[0].strip())
        
    return df

if __name__ == "__main__":
    df = fetch_live_listings(2)
    print(f"Scraped {len(df)} listings.")
    print(df.head())
