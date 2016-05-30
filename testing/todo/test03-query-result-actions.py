from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import Select
from selenium.common.exceptions import NoSuchElementException
import unittest, time, re

class QueryResultActions_03(unittest.TestCase):
    def setUp(self):
        self.driver = webdriver.Firefox()
        self.driver.implicitly_wait(30)
        self.base_url = "http://shepseskaf.roe.ac.uk/"
        self.verificationErrors = []
        self.accept_next_alert = True
    
    def test_03_query_result_actions(self):
        driver = self.driver
        driver.get(self.base_url + "/")
        driver.find_element_by_css_selector("div > #textfield").clear()
        driver.find_element_by_css_selector("div > #textfield").send_keys("se top 10 * from atlassource")
        driver.find_element_by_css_selector("input.main_buttons_submit").click()
        driver.find_element_by_xpath("//div[@id='votable_wrapper']/div[4]/div/div/table/thead/tr/th[4]/div").click()
        driver.find_element_by_id("ToolTables_votable_2").click()
        driver.find_element_by_css_selector("form.launch_viewer > div > input[type=\"submit\"]").click()
        driver.find_element_by_css_selector("label > input[type=\"text\"]").clear()
        driver.find_element_by_css_selector("label > input[type=\"text\"]").send_keys("180.51")
        self.assertEqual("Copied 1 row to the clipboard", self.close_alert_and_get_its_text())
    
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
    
    def tearDown(self):
        self.driver.quit()
        self.assertEqual([], self.verificationErrors)

if __name__ == "__main__":
    unittest.main()
