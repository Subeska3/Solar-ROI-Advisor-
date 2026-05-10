"""
Solar ROI Advisor - Streamlit UI
Author: Mohanras.A.S.A | MSc AI Assignment
"""

import streamlit as st
import clips
import os

# =========================================================
# PAGE CONFIG
# =========================================================

st.set_page_config(
    page_title="Solar ROI Advisor — Sri Lanka",
    page_icon="☀️",
    layout="wide"
)

# =========================================================
# HEADER
# =========================================================

st.title("☀️ Solar Panel ROI Advisor")

st.subheader(
    "Expert System for Sri Lanka — 2026 Crisis Edition"
)

st.markdown(
    "Powered by **CLIPS** rule engine. "
    "Recommends solar system size, "
    "solar scheme, and estimated ROI."
)

# =========================================================
# SIDEBAR
# =========================================================

st.sidebar.header("🏠 Household Details")

# =========================================================
# MONTHLY UNITS ONLY
# =========================================================

monthly_units = st.sidebar.number_input(
    "Monthly Electricity Usage (kWh)",
    min_value=1,
    max_value=5000,
    value=250,
    step=10
)

district = st.sidebar.selectbox(
    "District",
    [
        "colombo",
        "gampaha",
        "kandy",
        "anuradhapura",
        "polonnaruwa",
        "kurunegala",
        "jaffna",
        "trincomalee",
        "hambantota",
        "galle",
        "matara",
        "nuwara-eliya"
    ]
)

roof_area = st.sidebar.slider(
    "Roof Area (sqm)",
    10,
    200,
    50
)

roof_orientation = st.sidebar.selectbox(
    "Roof Orientation",
    [
        "south",
        "east-west",
        "north"
    ]
)

roof_shading = st.sidebar.selectbox(
    "Roof Shading",
    [
        "none",
        "partial",
        "heavy"
    ]
)

budget = st.sidebar.number_input(
    "Available Budget (LKR)",
    min_value=50000,
    max_value=10000000,
    value=800000,
    step=50000
)

loan_eligible = st.sidebar.selectbox(
    "Bank Loan Eligible?",
    [
        "yes",
        "no"
    ]
)

# =========================================================
# APPLIANCES
# =========================================================

st.sidebar.header("⚡ Appliance Usage")

num_ac = st.sidebar.slider(
    "Number of Air Conditioners",
    0,
    10,
    1
)

has_ev = st.sidebar.selectbox(
    "Electric Vehicle Charging?",
    [
        "yes",
        "no"
    ]
)

has_water_heater = st.sidebar.selectbox(
    "Electric Water Heater?",
    [
        "yes",
        "no"
    ]
)

# =========================================================
# BATTERY
# =========================================================

st.sidebar.header("🔋 Battery & Backup")

power_cut_frequency = st.sidebar.selectbox(
    "Power Cut Frequency",
    [
        "rare",
        "occasional",
        "frequent"
    ]
)

battery_preference = st.sidebar.selectbox(
    "Need Battery Backup?",
    [
        "yes",
        "no"
    ]
)

# =========================================================
# CONSUMPTION PATTERN
# =========================================================

st.sidebar.header("⏰ Consumption Pattern")

time_usage = st.sidebar.selectbox(
    "Peak Electricity Usage Time",
    [
        "daytime",
        "nighttime",
        "balanced"
    ]
)

# =========================================================
# USER PREFERENCES
# =========================================================

st.sidebar.header("🌱 User Preferences")

user_priority = st.sidebar.selectbox(
    "Primary Goal",
    [
        "lowest-cost",
        "fastest-roi",
        "eco-friendly",
        "future-expansion"
    ]
)

# =========================================================
# SYSTEM PREFERENCES
# =========================================================

st.sidebar.header("🔧 System Preferences")

panel_type = st.sidebar.selectbox(
    "Preferred Solar Panel Type",
    [
        "mono-perc",
        "topcon",
        "bifacial"
    ]
)

future_expansion = st.sidebar.selectbox(
    "Planning Future Expansion?",
    [
        "yes",
        "no"
    ]
)

# =========================================================
# RUN BUTTON
# =========================================================

run = st.sidebar.button(
    "🔍 Get Recommendation",
    type="primary",
    use_container_width=True
)

# =========================================================
# MAIN LAYOUT
# =========================================================

col1, col2 = st.columns([2, 1])

with col1:

    st.header("🤖 Expert System Output")

    output_area = st.empty()

with col2:

    st.header("📊 Inputs")

    st.metric(
        "Monthly Usage",
        f"{monthly_units} kWh"
    )

    st.metric(
        "District",
        district.title()
    )

    st.metric(
        "Roof Area",
        f"{roof_area} sqm"
    )

# =========================================================
# OUTPUT CAPTURE ROUTER
# =========================================================

class CaptureRouter(clips.Router):

    def __init__(self):

        super().__init__('capture', 40)

        self.output = ""

    def query(self, name):

        return name in (
            'stdout',
            'wdisplay',
            'wtrace',
            'wdialog',
            'wclips'
        )

    def write(self, name, message):

        self.output += message

# =========================================================
# RUN CLIPS
# =========================================================

def run_solar_es():

    try:

        env = clips.Environment()

        router = CaptureRouter()

        env.add_router(router)

        clp_path = os.path.join(
            os.path.dirname(
                os.path.abspath(__file__)
            ),
            "solar_roi.clp"
        )

        if not os.path.exists(clp_path):

            return "❌ solar_roi.clp file not found"

        env.load(clp_path)

        env.reset()

        # =================================================
        # WATCHES
        # =================================================

        # env.eval("(watch rules)")
        # env.eval("(watch facts)")
        # env.eval("(watch activations)")

        # =================================================
        # ASSERT FACT
        # =================================================

        fact = (
            f'(household '
            f'(id h1) '
            f'(monthly-units {monthly_units}) '
            f'(district {district}) '
            f'(roof-area-sqm {roof_area}) '
            f'(roof-orientation {roof_orientation}) '
            f'(roof-shading {roof_shading}) '
            f'(budget-lkr {budget}) '
            f'(loan-eligible {loan_eligible}) '
            f'(num-ac {num_ac}) '
            f'(has-ev {has_ev}) '
            f'(has-water-heater {has_water_heater}) '
            f'(power-cut-frequency {power_cut_frequency}) '
            f'(battery-preference {battery_preference}) '
            f'(time-usage {time_usage}) '
            f'(user-priority {user_priority}) '
            f'(panel-type {panel_type}) '
            f'(future-expansion {future_expansion}))'
        )

        router.output += "\n========== ASSERTED FACT ==========\n"

        router.output += fact + "\n"

        env.assert_string(fact)

        router.output += (
            "\n========== RUNNING INFERENCE ENGINE ==========\n"
        )

        env.run()

        router.output += (
            "\n========== INFERENCE COMPLETED ==========\n"
        )

        if router.output:

            return router.output

        return "⚠️ No output generated"

    except Exception as e:

        return f"❌ ERROR:\n{str(e)}"

# =========================================================
# EXECUTE
# =========================================================

if run:

    with st.spinner("Running expert system..."):

        result = run_solar_es()

    st.subheader("🧠 Inference Trace")

    if result and result.strip():

        output_area.code(
            result,
            language="text"
        )

        st.success(
            "✅ Recommendation generated successfully"
        )

    else:

        output_area.warning(
            "No output generated"
        )

# =========================================================
# FOOTER
# =========================================================

st.markdown("---")

st.caption(
    "📚 CLIPS 6.4.2 + clipspy 1.0.6 | "
    "Solar ROI Expert System for Sri Lanka"
)