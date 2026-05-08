;;; ==========================================================
;;; SOLAR PANEL ROI ADVISOR FOR SRI LANKA
;;; Author: Mohanras.A.S.A | MSc AI Assignment
;;; ==========================================================

(deftemplate household
   (slot id)
   (slot monthly-bill-lkr)
   (slot monthly-units)
   (slot district)
   (slot roof-area-sqm)
   (slot roof-orientation)
   (slot roof-shading)
   (slot budget-lkr)
   (slot loan-eligible))

(deftemplate tariff-slab
   (slot label)
   (slot min-units)
   (slot max-units)
   (slot rate-per-unit))

(deftemplate district-sun
   (slot district)
   (slot peak-sun-hours)
   (slot zone))

(deftemplate finance-option
   (slot scheme)
   (slot interest-rate)
   (slot tenure-years))

(deftemplate analysis
   (slot household-id)
   (slot avg-tariff (default 0))
   (slot recommended-kw (default 0))
   (slot generation-units (default 0))
   (slot system-cost-lkr (default 0))
   (slot scheme (default none))
   (slot payback-years (default 0))
   (slot reason (default "pending")))

(deffacts ceb-tariff-slabs
   (tariff-slab (label slab-1) (min-units 0)   (max-units 60)   (rate-per-unit 12))
   (tariff-slab (label slab-2) (min-units 61)  (max-units 90)   (rate-per-unit 30))
   (tariff-slab (label slab-3) (min-units 91)  (max-units 120)  (rate-per-unit 37))
   (tariff-slab (label slab-4) (min-units 121) (max-units 180)  (rate-per-unit 48))
   (tariff-slab (label slab-5) (min-units 181) (max-units 9999) (rate-per-unit 75)))

(deffacts district-sun-data
   (district-sun (district hambantota)   (peak-sun-hours 5.6) (zone dry))
   (district-sun (district anuradhapura) (peak-sun-hours 5.5) (zone dry))
   (district-sun (district jaffna)       (peak-sun-hours 5.7) (zone dry))
   (district-sun (district trincomalee)  (peak-sun-hours 5.5) (zone dry))
   (district-sun (district polonnaruwa)  (peak-sun-hours 5.4) (zone dry))
   (district-sun (district kurunegala)   (peak-sun-hours 5.0) (zone intermediate))
   (district-sun (district colombo)      (peak-sun-hours 4.8) (zone wet))
   (district-sun (district gampaha)      (peak-sun-hours 4.7) (zone wet))
   (district-sun (district galle)        (peak-sun-hours 4.7) (zone wet))
   (district-sun (district matara)       (peak-sun-hours 4.8) (zone wet))
   (district-sun (district kandy)        (peak-sun-hours 4.2) (zone intermediate))
   (district-sun (district nuwara-eliya) (peak-sun-hours 4.0) (zone hill)))

(deffacts finance-options
   (finance-option (scheme cash)      (interest-rate 0)  (tenure-years 0))
   (finance-option (scheme ceb-loan)  (interest-rate 9)  (tenure-years 7))
   (finance-option (scheme bank-loan) (interest-rate 14) (tenure-years 5)))

(defrule estimate-monthly-units
   (declare (salience 100))
   ?h <- (household (id ?id) (monthly-bill-lkr ?bill) (monthly-units 0))
   =>
   (bind ?est-units (round (/ ?bill 45)))
   (modify ?h (monthly-units ?est-units))
   (printout t "  >> Estimated consumption: " ?est-units " units/month" crlf))

(defrule classify-low-consumer
   (declare (salience 90))
   (household (id ?id) (monthly-units ?u))
   (test (<= ?u 90))
   =>
   (assert (analysis (household-id ?id) (avg-tariff 20)))
   (printout t "  >> Low-consumption household, avg ~LKR 20/unit" crlf))

(defrule classify-mid-consumer
   (declare (salience 90))
   (household (id ?id) (monthly-units ?u))
   (test (and (> ?u 90) (<= ?u 180)))
   =>
   (assert (analysis (household-id ?id) (avg-tariff 42)))
   (printout t "  >> Mid-consumption household, avg ~LKR 42/unit" crlf))

(defrule classify-high-consumer
   (declare (salience 90))
   (household (id ?id) (monthly-units ?u))
   (test (> ?u 180))
   =>
   (assert (analysis (household-id ?id) (avg-tariff 60)))
   (printout t "  >> HIGH-consumption household, avg ~LKR 60/unit (best ROI candidate!)" crlf))

(defrule recommend-system-size
   (declare (salience 80))
   (household (id ?id) (monthly-units ?u) (district ?d))
   (district-sun (district ?d) (peak-sun-hours ?psh))
   ?a <- (analysis (household-id ?id) (recommended-kw 0))
   =>
   (bind ?gen-per-kw (* ?psh 30 0.75))
   (bind ?required-kw (/ ?u ?gen-per-kw))
   (bind ?rec-kw (/ (round (* ?required-kw 2)) 2.0))
   (if (< ?rec-kw ?required-kw) then (bind ?rec-kw (+ ?rec-kw 0.5)))
   (bind ?gen-units (* ?rec-kw ?gen-per-kw))
   (bind ?cost (* ?rec-kw 220000))
   (modify ?a (recommended-kw ?rec-kw)
              (generation-units ?gen-units)
              (system-cost-lkr ?cost))
   (printout t "  >> Recommended size: " ?rec-kw " kW" crlf)
   (printout t "  >> Expected generation: " (round ?gen-units) " units/month" crlf)
   (printout t "  >> System cost: LKR " ?cost crlf))

(defrule warn-insufficient-roof
   (declare (salience 70))
   (household (id ?id) (roof-area-sqm ?roof))
   (analysis (household-id ?id) (recommended-kw ?kw))
   (test (> ?kw 0))
   (test (< ?roof (* ?kw 10)))
   =>
   (printout t "[!] WARNING: Roof area (" ?roof " sqm) insufficient for "
             ?kw " kW system. Need at least " (* ?kw 10) " sqm." crlf)
   (printout t "    Consider downsizing or partial coverage." crlf))

(defrule warn-shading
   (declare (salience 70))
   (household (id ?id) (roof-shading heavy))
   =>
   (printout t "[!] Heavy roof shading detected - generation may drop 30-50 percent." crlf)
   (printout t "    Trim trees or relocate panels before installation." crlf))

(defrule warn-orientation
   (declare (salience 70))
   (household (id ?id) (roof-orientation north))
   =>
   (printout t "[!] North-facing roof has 15-20 percent lower yield in Sri Lanka." crlf)
   (printout t "    Consider tilted mounting frames to face south." crlf))

(defrule confirm-good-roof
   (declare (salience 70))
   (household (id ?id) (roof-area-sqm ?roof) (roof-shading none) (roof-orientation ?o))
   (analysis (household-id ?id) (recommended-kw ?kw))
   (test (> ?kw 0))
   (test (>= ?roof (* ?kw 10)))
   (test (or (eq ?o south) (eq ?o east-west)))
   =>
   (printout t "[OK] Roof is suitable for full installation." crlf))

(defrule recommend-net-metering
   (declare (salience 60))
   (household (id ?id) (monthly-units ?u))
   ?a <- (analysis (household-id ?id) (generation-units ?g) (scheme none))
   (test (> ?g 0))
   (test (and (>= ?g (* ?u 0.85)) (<= ?g (* ?u 1.15))))
   =>
   (modify ?a (scheme net-metering)
              (reason "Generation matches consumption - bank credits via Net Metering"))
   (printout t "  >> SCHEME: Net Metering (generation ~ consumption)" crlf))

(defrule recommend-net-accounting
   (declare (salience 60))
   (household (id ?id) (monthly-units ?u))
   ?a <- (analysis (household-id ?id) (generation-units ?g) (scheme none))
   (test (> ?g (* ?u 1.15)))
   (test (<= ?g (* ?u 1.5)))
   =>
   (modify ?a (scheme net-accounting)
              (reason "Surplus generation - get cash payout via Net Accounting"))
   (printout t "  >> SCHEME: Net Accounting (cash for surplus)" crlf))

(defrule recommend-net-plus
   (declare (salience 60))
   (household (id ?id) (monthly-units ?u))
   ?a <- (analysis (household-id ?id) (generation-units ?g) (scheme none))
   (test (> ?g (* ?u 1.5)))
   =>
   (modify ?a (scheme net-plus)
              (reason "Large surplus - sell all generation as income via Net Plus"))
   (printout t "  >> SCHEME: Net Plus (treat as income-generating asset)" crlf))

(defrule recommend-net-metering-undersized
   (declare (salience 60))
   (household (id ?id) (monthly-units ?u))
   ?a <- (analysis (household-id ?id) (generation-units ?g) (scheme none))
   (test (> ?g 0))
   (test (< ?g (* ?u 0.85)))
   =>
   (modify ?a (scheme net-metering)
              (reason "Partial coverage - Net Metering reduces bill"))
   (printout t "  >> SCHEME: Net Metering (system covers part of usage)" crlf))

(defrule calculate-payback
   (declare (salience 50))
   ?a <- (analysis (household-id ?id)
                   (avg-tariff ?rate)
                   (generation-units ?g)
                   (system-cost-lkr ?cost)
                   (payback-years 0))
   (test (> ?cost 0))
   =>
   (bind ?monthly-savings (* ?g ?rate))
   (bind ?annual-savings (* ?monthly-savings 12))
   (bind ?payback (/ ?cost ?annual-savings))
   (modify ?a (payback-years ?payback))
   (printout t "  >> Monthly savings: LKR " (round ?monthly-savings) crlf)
   (printout t "  >> Payback period: " (round ?payback) " years" crlf))

(defrule advise-cash-purchase
   (declare (salience 40))
   (household (id ?id) (budget-lkr ?budget))
   (analysis (household-id ?id) (system-cost-lkr ?cost))
   (test (> ?cost 0))
   (test (>= ?budget ?cost))
   =>
   (printout t crlf "[FIN] FINANCING: Cash purchase recommended" crlf)
   (printout t "      Best ROI - no interest cost." crlf))

(defrule advise-ceb-loan
   (declare (salience 40))
   (household (id ?id) (budget-lkr ?budget) (loan-eligible yes))
   (analysis (household-id ?id) (system-cost-lkr ?cost))
   (test (> ?cost 0))
   (test (< ?budget ?cost))
   =>
   (bind ?gap (- ?cost ?budget))
   (printout t crlf "[FIN] FINANCING: Apply for CEB rooftop financing scheme" crlf)
   (printout t "      Funding gap: LKR " ?gap " (~9 percent interest, 7 yr tenure)" crlf)
   (printout t "      Monthly EMI offset by solar savings." crlf))

(defrule advise-bank-loan
   (declare (salience 35))
   (household (id ?id) (budget-lkr ?budget) (loan-eligible yes))
   (analysis (household-id ?id) (system-cost-lkr ?cost))
   (test (> ?cost 0))
   (test (< ?budget ?cost))
   =>
   (printout t "[FIN] ALT FINANCING: Bank green loan (BOC/Sampath/HNB)" crlf)
   (printout t "      ~14 percent interest, 5 yr tenure - higher EMI but faster payoff" crlf))

(defrule advise-no-loan
   (declare (salience 40))
   (household (id ?id) (budget-lkr ?budget) (loan-eligible no))
   (analysis (household-id ?id) (system-cost-lkr ?cost))
   (test (> ?cost 0))
   (test (< ?budget ?cost))
   =>
   (bind ?affordable-kw (/ ?budget 220000))
   (bind ?affordable-kw (/ (round (* ?affordable-kw 2)) 2.0))
   (printout t crlf "[FIN] FINANCING: Phased installation recommended" crlf)
   (printout t "      Start with " ?affordable-kw " kW within budget; expand later." crlf))

(defrule advisory-low-consumer-warning
   (declare (salience 30))
   (household (id ?id) (monthly-units ?u))
   (test (<= ?u 90))
   =>
   (printout t crlf "[!] NOTE: Your consumption is low (subsidised slabs)." crlf)
   (printout t "    Solar payback will be slower than for high-bill households." crlf)
   (printout t "    Net Plus scheme may be more attractive than self-use." crlf))

(defrule advisory-high-consumer-encourage
   (declare (salience 30))
   (household (id ?id) (monthly-units ?u))
   (analysis (household-id ?id) (payback-years ?p))
   (test (> ?u 180))
   (test (> ?p 0))
   (test (< ?p 5))
   =>
   (printout t crlf "[$$] EXCELLENT ROI: High tariff slab + good payback." crlf)
   (printout t "     Solar is a strong investment for your household." crlf))

(defrule advisory-dry-zone-bonus
   (declare (salience 30))
   (household (id ?id) (district ?d))
   (district-sun (district ?d) (zone dry))
   =>
   (printout t crlf "[SUN] Dry zone advantage: high sun hours = better generation." crlf))

(defrule advisory-hill-country-warning
   (declare (salience 30))
   (household (id ?id) (district ?d))
   (district-sun (district ?d) (zone hill))
   =>
   (printout t crlf "[CLOUD] Hill country: lower sun hours, longer payback." crlf)
   (printout t "        Consider higher-efficiency panels (mono-PERC, TOPCon)." crlf))

(defrule print-summary
   (declare (salience 1))
   (analysis (household-id ?id)
             (recommended-kw ?kw)
             (generation-units ?g)
             (system-cost-lkr ?cost)
             (scheme ?s)
             (payback-years ?p)
             (reason ?r))
   (test (> ?kw 0))
   =>
   (printout t crlf
             "=================================================" crlf
             "          SOLAR INSTALLATION RECOMMENDATION       " crlf
             "=================================================" crlf
             "  System size:    " ?kw " kW" crlf
             "  Generation:     " (round ?g) " units/month" crlf
             "  System cost:    LKR " ?cost crlf
             "  Best scheme:    " ?s crlf
             "  Payback period: " (round ?p) " years" crlf
             "  Rationale:      " ?r crlf
             "=================================================" crlf))