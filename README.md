# ☀️ Solar Panel ROI Advisor (Sri Lanka)

An expert system powered by **CLIPS** to recommend optimal solar panel setups for households in Sri Lanka. Developed as part of an MSc AI Assignment.

## 📌 Project Overview
The **Solar ROI Advisor** takes a household's specifics (such as electricity bill, location, roof area, and available budget) and uses a rule-based expert system to determine:
- The recommended **Solar System Size** (in kW).
- The expected **Monthly Generation** (in units).
- The estimated **System Cost**.
- The most suitable CEB **Solar Scheme** (Net Metering, Net Accounting, or Net Plus).
- The estimated **Payback Period** (in years).
- Financing and Advisory Recommendations based on individual profiles.

## ⚙️ Technology Stack
- **Python 3.x**
- **Streamlit**: For the interactive web UI.
- **CLIPS (clipspy)**: The inference engine used to execute the expert system rules.

## 📂 Project Structure
- `streamlit_solar.py` - The main Streamlit web application script. It handles the UI, collects inputs, and runs the CLIPS inference engine.
- `solar_roi.clp` - The CLIPS rule-base defining tariffs, sun-hours by district, financing options, and recommendation rules.
- `requirements.txt` - Project dependencies for easy installation and deployment.

## 🚀 How to Run Locally

### 1. Clone the repository
```bash
git clone https://github.com/Subeska3/Solar-ROI-Advisor-.git
cd Solar-ROI-Advisor-
```

### 2. Install Dependencies
Make sure you have Python installed, then run:
```bash
pip install -r requirements.txt
```

### 3. Run the Streamlit App
```bash
streamlit run streamlit_solar.py
```
This will launch the app in your default web browser (typically at `http://localhost:8501`).

## ☁️ Deployment
This application is fully compatible with **Streamlit Community Cloud**. To deploy:
1. Push the code to a GitHub repository.
2. Go to [share.streamlit.io](https://share.streamlit.io/).
3. Connect your repository and select `streamlit_solar.py` as the main file.
4. Click **Deploy**.

## 👨‍💻 Author
**Mohanras.A.S.A** | MSc in AI Assignment
