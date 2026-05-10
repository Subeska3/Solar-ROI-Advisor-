;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SOLAR ROI EXPERT SYSTEM — FINAL VERSION
;; Author: Mohanras.A.S.A
;; MSc AI Assignment
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; TEMPLATES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(deftemplate household

   (slot id)

   ;; USER PROVIDED MONTHLY USAGE
   (slot monthly-units)

   ;; LOCATION
   (slot district)

   ;; ROOF DETAILS
   (slot roof-area-sqm)
   (slot roof-orientation)
   (slot roof-shading)

   ;; FINANCIALS
   (slot budget-lkr)
   (slot loan-eligible)

   ;; APPLIANCES
   (slot num-ac)
   (slot has-ev)
   (slot has-water-heater)

   ;; BATTERY / POWER
   (slot power-cut-frequency)
   (slot battery-preference)

   ;; CONSUMPTION PATTERN
   (slot time-usage)

   ;; USER GOAL
   (slot user-priority)

   ;; PANEL PREFERENCE
   (slot panel-type)

   ;; FUTURE EXPANSION
   (slot future-expansion)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(deftemplate consumer-profile

   (slot type)
   (slot avg-tariff)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(deftemplate solar-recommendation

   (slot system-size-kw)
   (slot estimated-cost)
   (slot expected-generation)
   (slot confidence)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(deftemplate scheme

   (slot type)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; INPUT VALIDATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule missing-monthly-units

   (declare (salience 100))

   (household
      (monthly-units 0)
   )

   =>

   (printout t
      "[ERROR] Monthly electricity usage missing."
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule missing-roof-area

   (declare (salience 100))

   (household
      (roof-area-sqm 0)
   )

   =>

   (printout t
      "[ERROR] Roof area missing."
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule missing-budget

   (declare (salience 100))

   (household
      (budget-lkr 0)
   )

   =>

   (printout t
      "[ERROR] Budget information missing."
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CONSUMER CLASSIFICATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule classify-low-consumer

   (declare (salience 90))

   (household
      (monthly-units ?u&:(<= ?u 90))
   )

   =>

   (assert

      (consumer-profile
         (type low)
         (avg-tariff 20)
      )
   )

   (printout t
      "[RULE] classify-low-consumer fired"
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule classify-mid-consumer

   (declare (salience 90))

   (household
      (monthly-units ?u&:(and (> ?u 90) (<= ?u 180)))
   )

   =>

   (assert

      (consumer-profile
         (type medium)
         (avg-tariff 42)
      )
   )

   (printout t
      "[RULE] classify-mid-consumer fired"
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule classify-high-consumer

   (declare (salience 90))

   (household
      (monthly-units ?u&:(> ?u 180))
   )

   =>

   (assert

      (consumer-profile
         (type high)
         (avg-tariff 60)
      )
   )

   (printout t
      "[RULE] classify-high-consumer fired"
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SOLAR SYSTEM SIZE RECOMMENDATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule recommend-system-size

   (declare (salience 80))

   (household

      (monthly-units ?units)
      (roof-shading ?shade)
      (roof-orientation ?orientation)
      (panel-type ?panel)
   )

   =>

   ;; BASE GENERATION
   (bind ?generation-per-kw 120)

   ;; SHADING ADJUSTMENT
   (if (eq ?shade heavy)
      then
      (bind ?generation-per-kw 90)
   )

   (if (eq ?shade partial)
      then
      (bind ?generation-per-kw 105)
   )

   ;; ORIENTATION ADJUSTMENT
   (if (eq ?orientation north)
      then
      (bind ?generation-per-kw (- ?generation-per-kw 10))
   )

   ;; PANEL TYPE BONUS
   (if (eq ?panel topcon)
      then
      (bind ?generation-per-kw (+ ?generation-per-kw 10))
   )

   (if (eq ?panel bifacial)
      then
      (bind ?generation-per-kw (+ ?generation-per-kw 15))
   )

   ;; REQUIRED SYSTEM SIZE
   (bind ?required-kw (/ ?units ?generation-per-kw))

   ;; COST ESTIMATION
   (bind ?cost (* ?required-kw 180000))

   ;; EXPECTED GENERATION
   (bind ?generation (* ?required-kw ?generation-per-kw))

   ;; CONFIDENCE
   (bind ?confidence 0.88)

   ;; BETTER CONFIDENCE FOR GOOD ROOF
   (if (and
         (eq ?shade none)
         (neq ?orientation north))
      then
      (bind ?confidence 0.95)
   )

   (assert

      (solar-recommendation

         (system-size-kw ?required-kw)
         (estimated-cost ?cost)
         (expected-generation ?generation)
         (confidence ?confidence)
      )
   )

   (printout t
      "[RULE] recommend-system-size fired"
      crlf
   )

   (printout t
      "Recommended System Size = "
      ?required-kw
      " kW"
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ROOF VALIDATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule warn-heavy-shading

   (declare (salience 70))

   (household
      (roof-shading heavy)
   )

   =>

   (printout t
      "[WARNING] Heavy roof shading detected."
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule warn-north-orientation

   (declare (salience 70))

   (household
      (roof-orientation north)
   )

   =>

   (printout t
      "[WARNING] North-facing roof reduces efficiency."
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule confirm-good-roof

   (declare (salience 70))

   (household
      (roof-shading none)
      (roof-orientation south)
   )

   =>

   (printout t
      "[INFO] Roof conditions are ideal."
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BATTERY RECOMMENDATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule recommend-battery

   (declare (salience 65))

   (household

      (battery-preference yes)
   )

   =>

   (printout t
      "[INFO] Hybrid inverter + battery backup recommended."
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule frequent-power-cuts

   (declare (salience 65))

   (household

      (power-cut-frequency frequent)
   )

   =>

   (printout t
      "[INFO] Frequent power cuts detected."
      crlf
   )

   (printout t
      "[INFO] Battery storage highly recommended."
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ELECTRIC VEHICLE ANALYSIS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule detect-ev-load

   (declare (salience 60))

   (household
      (has-ev yes)
   )

   =>

   (printout t
      "[INFO] EV charging increases future electricity demand."
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FUTURE EXPANSION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule future-expansion-advice

   (declare (salience 60))

   (household
      (future-expansion yes)
   )

   =>

   (printout t
      "[INFO] Design system with expansion capability."
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SCHEME RECOMMENDATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule recommend-net-metering

   (declare (salience 50))

   (solar-recommendation
      (system-size-kw ?kw&:(<= ?kw 5))
   )

   =>

   (assert

      (scheme
         (type net-metering)
      )
   )

   (printout t
      "[RULE] recommend-net-metering fired"
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule recommend-net-accounting

   (declare (salience 50))

   (solar-recommendation
      (system-size-kw ?kw&:(> ?kw 5))
   )

   =>

   (assert

      (scheme
         (type net-accounting)
      )
   )

   (printout t
      "[RULE] recommend-net-accounting fired"
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FINANCIAL ALTERNATIVES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule suggest-phased-installation

   (declare (salience 40))

   (solar-recommendation
      (estimated-cost ?cost)
   )

   (household
      (budget-lkr ?budget)
   )

   (test (< ?budget ?cost))

   =>

   (printout t
      "[ALTERNATIVE] Budget lower than estimated cost."
      crlf
   )

   (printout t
      "[ALTERNATIVE] Consider phased installation."
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule suggest-bank-loan

   (declare (salience 40))

   (household
      (loan-eligible yes)
   )

   =>

   (printout t
      "[ALTERNATIVE] Green energy loan available."
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PAYBACK CALCULATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule calculate-payback

   (declare (salience 30))

   (solar-recommendation

      (estimated-cost ?cost)
      (system-size-kw ?kw)
   )

   =>

   ;; APPROXIMATE ANNUAL SAVINGS
   (bind ?annual-savings (* ?kw 90000))

   ;; PAYBACK
   (bind ?payback (/ ?cost ?annual-savings))

   (printout t
      "[RULE] calculate-payback fired"
      crlf
   )

   (printout t
      "Estimated Annual Savings = LKR "
      ?annual-savings
      crlf
   )

   (printout t
      "Estimated Payback Period = "
      ?payback
      " years"
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DISTRICT ADVISORY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule advisory-dry-zone

   (declare (salience 20))

   (household
      (district ?d)
   )

   (test

      (or

         (eq ?d anuradhapura)
         (eq ?d polonnaruwa)
         (eq ?d hambantota)
      )
   )

   =>

   (printout t
      "[INFO] High solar irradiance district detected."
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FINAL SUMMARY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule final-summary

   (declare (salience -100))

   (solar-recommendation

      (system-size-kw ?kw)
      (estimated-cost ?cost)
      (expected-generation ?gen)
      (confidence ?conf)
   )

   (scheme
      (type ?scheme)
   )

   =>

   (printout t crlf)

   (printout t
      "===================================="
      crlf
   )

   (printout t
      "FINAL SOLAR RECOMMENDATION"
      crlf
   )

   (printout t
      "===================================="
      crlf
   )

   (printout t
      "Recommended System Size : "
      ?kw
      " kW"
      crlf
   )

   (printout t
      "Estimated System Cost   : LKR "
      ?cost
      crlf
   )

   (printout t
      "Expected Monthly Output : "
      ?gen
      " units"
      crlf
   )

   (printout t
      "Recommended Scheme      : "
      ?scheme
      crlf
   )

   (printout t
      "Confidence Score        : "
      (* ?conf 100)
      "%"
      crlf
   )

   (printout t
      "===================================="
      crlf
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; END OF FILE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;