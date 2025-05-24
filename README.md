# RealforceControl
Library and application for interacting with [Realforce](https://www.realforce.co.jp) USB keyboards on macOS,
specifically the [GX1](https://www.realforce.co.jp/en/products/series_gaming_gx1.html) model that is not officially
supported on macOS.

**WARNING:** This software directly interacts with vendor-specific extensions of the HID standard. This may have
unintended consequences and could brick the keyboard, even though it only sends commands that are used by the official
Windows software as well.

## Requirements
The software requires macOS 15.0 "Sequoia" due to use of the CoreHID framework. So far, it has only been tested with a
Topre Realforce GX1 X1UDM1 KB0772 Hatsune Miku Collaboration Model, but it should work with others as well.

## Contact & Support
Please report any issues on [GitHub](https://github.com/q-p/RealforceControl).
