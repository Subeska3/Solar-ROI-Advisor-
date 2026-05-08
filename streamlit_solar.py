"""
Solar ROI Advisor - Streamlit UI
Author: Mohanras.A.S.A | MSc AI Assignment
"""

import streamlit as st
import clips
import os

st.set_page_config(
    page_title="Solar ROI Advisor — Sri Lanka",
    page_icon="☀️",
    layout="wide"
)

st.title("☀️ Solar Panel ROI Advisor")
st.subheader("Expert System for Sri Lanka — 2026 Crisis Edition")
st.markdown(
    "Powered by **CLIPS** rule engine. Recommends panel size, "
    "scheme (Net Metering / Net Accounting / Net Plus), and payback period."
)

# ---------- Sidebar ----------
st.sidebar.header("🏠 Household Details")

monthly_bill = st.sidebar.number_input("Monthly CEB Bill (LKR)",
                                        min_value=500, max_value=100000,
                                        value=12000, step=500)

district = st.sidebar.selectbox(
    "District",
    ["colombo", "gampaha", "kandy", "anuradhapura", "polonnaruwa",
     "kurunegala", "jaffna", "trincomalee", "hambantota",
     "galle", "matara", "nuwara-eliya"],
    index=0
)

roof_area = st.sidebar.slider("Roof Area (sqm)", 10, 200, 50)

roof_orientation = st.sidebar.selectbox("Roof Orientation",
                                         ["south", "east-west", "north"])

roof_shading = st.sidebar.selectbox("Shading", ["none", "partial", "heavy"])

budget = st.sidebar.number_input("Available Budget (LKR)",
                                  min_value=50000, max_value=10000000,
                                  value=800000, step=50000)

loan_eligible = st.sidebar.selectbox("Bank Loan Eligible?", ["yes", "no"])

run = st.sidebar.button("🔍 Get Recommendation", type="primary",
                         use_container_width=True)

# ---------- Main ----------
col1, col2 = st.columns([2, 1])
with col1:
    st.header("🤖 Expert System Output")
    output_area = st.empty()
with col2:
    st.header("📊 Inputs")
    st.metric("Bill", f"LKR {monthly_bill:,}")
    st.metric("District", district.title())
    st.metric("Roof", f"{roof_area} sqm")


class CaptureRouter(clips.Router):
    def __init__(self):
        super().__init__('capture', 40)
        self.output = ""

    def query(self, name):
        return name in ('stdout', 'wdisplay', 'wtrace')

    def write(self, name, message):
        self.output += message

def run_solar_es(bill, dist, roof, ori, shade, bud, loan):
    env = clips.Environment()
    
    router = CaptureRouter()
    env.add_router(router)
    
    clp_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                            "solar_roi.clp")
    if not os.path.exists(clp_path):
        return f"❌ Cannot find solar_roi.clp at {clp_path}"

    env.load(clp_path)
    env.reset()

    fact = (f'(household (id h1) (monthly-bill-lkr {bill}) '
            f'(monthly-units 0) (district {dist}) '
            f'(roof-area-sqm {roof}) (roof-orientation {ori}) '
            f'(roof-shading {shade}) (budget-lkr {bud}) '
            f'(loan-eligible {loan}))')
    env.assert_string(fact)
    env.run()

    return router.output


if run:
    with st.spinner("Inference running..."):
        result = run_solar_es(monthly_bill, district, roof_area,
                              roof_orientation, roof_shading, budget,
                              loan_eligible)
    if result.strip():
        output_area.code(result, language="text")
        st.success("✅ Recommendation generated")
    else:
        output_area.warning("No output — check rules use (printout t ...)")

st.markdown("---")
st.caption("📚 CLIPS 6.4.2 + clipspy 1.0.6 | CEB tariff data Q2 2026")