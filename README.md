## SOP Payslip reader

This will read PDF files from the current directory and generate a CSV to STDOUT with various columns parsed from the PDF file.

* `From`
* `To`
* `Pay Basic`
* `Pay Basic Arrears`
* `Unpaid Leave`
* `Pymt Non Consol Perform Bonus`
* `Rec and Ret Allow`
* `PAYE`
* `Alpha Pension`
* `NI A`

The parsing is somewhat crude.. it looks for a line `Payments.*Deductions*` and then takes the following segement as a tabulated list of labelled values.

It makes use of the very handy [string scanner library](https://ruby-doc.org/stdlib-2.5.3/libdoc/strscan/rdoc/StringScanner.html) in ruby

## Dependencies

Install dependencies with bundler:

```
bundle install
```

## Usage

After placing PDF files in the current directory, execute using:

```
./payslip_parser.rb *.pdf > output.csv
```
