from openalpr import Alpr
from argparse import ArgumentParser
import locale

locale.setlocale(locale.LC_ALL, 'C')

def OCR():
    alpr = None
    try:
        alpr = Alpr("us", "/etc/openalpr/openalpr.conf","/usr/share/openalpr/runtime_data",)
        print("Test")

        if not alpr.is_loaded():
            print("Error loading OpenALPR")
        else:
            print("Using OpenALPR " + alpr.get_version())

        alpr.set_top_n(7)
        alpr.set_default_region("wa")
        alpr.set_detect_region(False)
        jpeg_bytes = open("/home/pi/Pictures/1637513466.jpg", "rb").read()
        results = alpr.recognize_array(jpeg_bytes)

#        i = 0
#        for plate in results['results']:
#            i += 1
#            print("Plate #%d" % i)
#            print("   %12s %12s" % ("Plate", "Confidence"))
#            for candidate in plate['candidates']:
#                prefix = "-"
#                if candidate['matches_template']:
#                    prefix = "*"
#
#                print("  %s %12s%12f" % (prefix, candidate['plate'], candidate['confidence']))
#                a=candidate['plate']
#                test = max(candidate['confidence'])

        a = results['results'][0]['plate']
        print(a)
        return a



    finally:
        if alpr:
            alpr.unload()

a=1
while(a==1):
    OCR()
    a = 2
