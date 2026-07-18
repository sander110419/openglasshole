# Hardware options and tradeoffs

The reference required-parts subtotal is **$46.59 USD** from
[`hardware/bom.csv`](../hardware/bom.csv). Prices and availability below were
checked on **2026-07-18**; the reference currency conversion remains the BOM's
2026-07-17 rate. Totals exclude shipping, tax, duties, failed prints, and any
new tether or enclosure not already covered by the BOM. A replacement option
subtracts the reference part before adding its price.

The BOM's generic `$0.40` `DISC1` allowance would make the known subtotal
$46.99, but it is not an exact sourced connector and has no release-force data.
It cannot be counted as a validated walking solution. The named magnetic
options below are better characterized, but both exceed $50, one was out of
stock when checked, and both still require the same off-head electrical and
pull tests.

These are prototype choices, not safety claims. None establishes outdoor
visibility, comfort, optical performance, battery life, breakaway behavior, or
suitability while walking. The contrast hood is for stationary use only. Never
use this project while driving, cycling, crossing roads, using stairs, or doing
another task where an obscured or distracting view can cause harm.

## Option matrix

| Option | Checked source and specification | Exact budget effect | Benefit | Tradeoff and validation status |
| --- | --- | ---: | --- | --- |
| **Reference protected 500 mAh cell** | [PKCELL LP503035 at TinyTronics](https://www.tinytronics.nl/en/power/batteries/li-po/pkcell-li-po-battery-3-7v-500mah-jst-ph-lp503035): EUR 4.75 / BOM value $5.45; not in stock, 2–4 week estimate; maximum 38×31×5.3 mm, 11 g, 500 mA maximum charge and continuous discharge. | **+$0.00 = $46.59** | Matches the reference cell cavity and the XIAO's published 380 mA charger. | **Reference, not physically validated.** Runtime, temperature, fit, lead strain, polarity, and Wi-Fi peak stability remain unmeasured. Availability is delayed. |
| **Smaller protected 500 mAh cell** | [Adafruit product 1578](https://www.adafruit.com/product/1578): $7.95, in stock; 29×36×4.75 mm, 10.5 g, 102 mm JST-PH lead. Its [datasheet](https://cdn-shop.adafruit.com/product-files/1578/Datasheet.pdf) gives 100 mA standard / 500 mA quick charge and 500 mA maximum continuous discharge. | $46.59 − $5.45 + $7.95 = **+$2.50 = $49.09** | About 21% less bounding-box volume and 0.5 g less mass than the reference cell. | **Vendor data checked; build unvalidated.** It adds no capacity, leaves only $0.91 of parts-subtotal margin, and needs padding/lead routing. Measure the received revision and verify polarity, temperature, and burst-current behavior before use. |
| **Off-body protected 1200 mAh cell** | [Adafruit product 258](https://www.adafruit.com/product/258): $9.95, in stock; 34×62×5 mm, 23 g, JST-PH. Adafruit limits charging to 500 mA; its [datasheet](https://cdn-shop.adafruit.com/product-files/258/C101-_Li-Polymer_503562_1200mAh_3.7V_with_PCM_APPROVED_8.18.pdf) gives 1.2 A maximum continuous discharge. | $46.59 − $5.45 + $9.95 = **+$4.50 = $51.09** | 2.4× nominal capacity while moving the cell off the glasses. Scaling the existing unmeasured estimates gives about 10.1 h worst sustained, 26.7 h always-connected, 44–69 h radio-off polling, or 60–120 h cached playback. | **Electrical candidate; mechanically and thermally unvalidated.** It exceeds $50 before the required rigid body enclosure, tether, connector, shipping, and tax. Cable drop, charge time, temperature, runtime, routing, and snag behavior require measurement. |
| **Four-contact magnetic connector pair** | [Adafruit product 5358](https://www.adafruit.com/product/5358): $6.50, out of stock; both halves included. The [drawing](https://cdn-shop.adafruit.com/product-files/5358/C17000-001_datasheet_MG04254F-RA-1S1N.pdf) gives a 21×7 mm face, roughly 4 mm body depth, 2.50 mm pitch, 2 A rating / 3 A peak, and 36 VDC maximum. Mass and release force are not specified. | $46.59 + $6.50 = **+$6.50 = $53.09** | Convenient detachable battery tether with enough contacts to parallel each battery rail. | **Unavailable and unvalidated.** It is not a certified safety breakaway. Pull force, canted or partial-mating shorts, contact bounce, resistance sharing, debris attraction, corrosion, strain relief, and every-direction release behavior are unknown. |
| **Compact three-contact magnetic pair** | [Adafruit product 5360](https://www.adafruit.com/product/5360): $5.95 and in stock when checked; both halves included. The [drawing](https://cdn-shop.adafruit.com/product-files/5360/5360_C17002_______-1.pdf) gives a 15×4 mm body, 5.5 mm overall height including terminals, 2.54 mm pitch, 2 A per-contact rating, 30 mΩ maximum contact resistance, and 20,000-cycle minimum. Mass, magnetic separation force, and cable strain relief are not specified. | $46.59 + $5.95 = **+$5.95 = $52.54** | The smallest currently orderable named tether connector found in this review; a symmetric three-contact battery assignment is possible. | **Available convenience candidate, not a safety device.** It exceeds $50 before shipping and needs custom insulated mounts. Exposed magnetic contacts can collect debris; pull force, canted/partial-mating shorts, bounce, corrosion, and every-direction release behavior remain untested. |
| **Neoprene glasses retainer** | [Representative Skullerz 3275 listing](https://www.lowes.com/pd/Skullerz-Plastic-Safety-Glasses/1001754310): $2.59 for one, listed for shipping; neoprene slide-over temple ends. The listing does not give reliable item dimensions or mass. | $46.59 + $2.59 = **+$2.59 = $49.18** | May reduce frame slip and improve stability under an asymmetric prototype load. | **Fit unvalidated.** It is not advertised as breakaway, does not secure the electronics to the frame, can interfere with the pods, and can transfer a snag load to the head. It creates no walking or safety assurance. |
| **Removable stationary contrast hood** | Existing black card/foam scrap allowance: $0.25. A complete [12×18 inch, 2 mm black foam sheet](https://www.michaels.com/product/12-x-18-foam-sheet-by-creatology-10597484) was $1.19. | Scrap: **+$0.25 = $46.84**. Buying the sheet: **+$1.19 = $47.78**. | Blocks ambient light behind the combiner and may permit lower OLED contrast indoors. It can also cover the positive lens in storage. | **Concept documented; not power- or fit-tested.** It blocks the world view and is stationary-only, not an outdoor-visibility fix. Mount it to a printed part, never to an optical coating, and remove it before any movement. |
| **Post-calibration ±2 mm focus trim** | No purchased part. After measuring the final OLED position on the focus bench, make a custom CAD preset with `FOCUS_MIN` and `FOCUS_MAX` 2 mm either side of that position. At the provisional 45 mm focus, 43–47 mm travel shortens the tunnel from 58.8 to about 53.8 mm. | **+$0.00 = $46.59** | Removes 5 mm, or about 8.5%, of optical-engine length while retaining 4 mm of service adjustment. It does not change the display, viewport, lens, Wi-Fi, or API. | **Custom-after-measurement option only.** The source release retains 38–52 mm travel because purchased lens BFL, OLED emitting-plane offset, prescription, and desired virtual distance vary. Shortening first can make focus impossible; regenerate and validate every mesh after changing the range. A fully fixed 51.8 mm tunnel could be shorter still but sacrifices all refocus margin and is not recommended before repeated physical measurements. |
| **Future vendor-finished 30×22×1.1 mm pane** | No exact-size 50R/50T-at-45° retail source or price has been verified. The comparator is the current [$18.89 30×30×1.1 mm pane](https://www.ebay.com/itm/353187332336). The first-order footprint in [`OPTICS.md`](OPTICS.md) is about 26.31×16.76 mm. | For a future pane price **P**: delta = **P − $18.89**; subtotal = **$27.70 + P**. It remains at or below $50 only when **P ≤ $22.30**. | At equal material and thickness, pane area falls from 900 to 660 mm², a 26.7% reduction. A 28×20 mm clear opening would retain about 0.84 mm horizontal and 1.62 mm vertical first-order margin around the modeled beam footprint. | **Future optical/mechanical experiment only.** There is no supplier, price, CAD export, mass, coating verification, or physical optical test. It needs a new fully captured soft-edge frame and complete eye-box, ghosting, prescription-lens, and clear-away validation. Never cut, grind, drill, or rework the current coated pane; order a vendor-finished part. |

## Remote-cell connector constraint

Keep the XIAO and OLED local and carry only the protected 1S battery rails over
the tether. Seeed specifies a 3.7 V battery input and 380 mA fast charging on
the [XIAO ESP32-C3 battery pads](https://wiki.seeedstudio.com/XIAO_ESP32C3_Getting_Started/).
For the compact three-contact experiment, use the same physical assignment on
both mating faces:

```text
[ switched BAT+ | BAT-/GND | switched BAT+ ]
```

Join the two outer contacts at each end. The centre contact carries the full
return current, which remains below its 2 A published rating in this design.
For a four-contact experiment, use:

```text
[ switched BAT+ | BAT-/GND | BAT-/GND | switched BAT+ ]
```

Join the two outer contacts at each end and join the two inner contacts at each
end; verify continuity and polarity before attaching a cell. Use short flexible
26–28 AWG power conductors with strain relief. Both palindromic assignments
reduce face-orientation ambiguity, but neither can prevent sliding, canted,
contaminated, or bouncing contacts from shorting or resetting the device.
Charge off-head and attended, and do not mate or unmate the battery connector
while USB is attached.
