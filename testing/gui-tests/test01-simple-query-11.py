from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
import unittest, time, re
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.ui import WebDriverWait # available since 2.4.0
from selenium.webdriver.support import expected_conditions as EC # available since 2.26.0



class simple_query_01_11(unittest.TestCase):
    
    def setUp(self):
        self.driver = webdriver.Firefox()
        self.driver.implicitly_wait(100)
        self.base_url = "http://shepseskaf.roe.ac.uk/#dbaccess_SQL_form_div"
        self.verificationErrors = []
        self.accept_next_alert = True
        self.row_count = 10
        self.page_count = 10
        self.votable_info_html = "Showing 1 to " + str(self.page_count) + " of " + str(self.row_count) + " entries"
        
    def test_01_simple_query_11(self):
        driver = self.driver
        driver.get(self.base_url)
        driver.execute_script("jQuery('#textfield').val('select top " + str(self.row_count) + " ra,dec  from atlassource');")
        driver.execute_script("jQuery('div > #textfield').text('select top " + str(self.row_count) + " ra,dec  from atlassource');")
        driver.execute_script("console.log(jQuery('#textfield').val())")
        driver.execute_script("console.log(jQuery('div > #textfield').text());")
        time.sleep(40)
        driver.find_element_by_css_selector("input.main_buttons_submit").click()
        votable_info_text = ""
        try:
            votable_info = driver.find_element_by_id('votable_info')
            votable_info_text = self.get_text_excluding_children(driver,votable_info).replace(",", "")
            self.assertEqual(votable_info_text, self.votable_info_html)
           
        except Exception as e:
            print e
            driver.quit()
            
    def is_element_present(self, how, what):
        try: self.driver.find_element(by=how, value=what)
        except NoSuchElementException, e: return False
        return True
    
    def is_alert_present(self):
        try: self.driver.switch_to_alert()
        except NoAlertPresentException, e: return False
        return True
    
    def close_alert_and_get_its_text(self):
        try:
            alert = self.driver.switch_to_alert()
            alert_text = alert.text
            if self.accept_next_alert:
                alert.accept()
            else:
                alert.dismiss()
            return alert_text
        finally: self.accept_next_alert = True
        
    def get_text_excluding_children(self,driver, element):
        return driver.execute_script("""
        return jQuery(arguments[0]).contents().filter(function() {
            return this.nodeType == Node.TEXT_NODE;
        }).text();
        """, element)
        
    def tearDown(self):
        self.driver.quit()
        self.assertEqual([], self.verificationErrors)

if __name__ == "__main__":
    unittest.main()
