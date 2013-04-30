require 'spec_helper'

describe "Dynamic Pubmed pages" do
	describe "Home page" do
		it "should have the content 'Sample App'" do
			visit '/dynamic_pubmed/home'
			page.should have_selector('h1', :text => 'Sample App')
		end

		it "should have the right title" do
			visit '/dynamic_pubmed/home'
			page.should have_selector('title',
						:text => "Dynamic Pubmed | Home")
		end
	end

	describe "Help page" do
		it "should have the content 'Help'" do
			visit '/dynamic_pubmed/help'
			page.should have_selector('h1', :text => 'Help')
		end

		it "should have the right title" do
			visit '/dynamic_pubmed/help'
			page.should have_selector('title',
						:text => "Dynamic Pubmed | Help")
		end
	end

	describe "About page" do
		it "should have the content 'About'" do
			visit '/dynamic_pubmed/about/'
			page.should have_selector('h1', :text => 'About')
		end

		it "should have the right title" do
			visit '/dynamic_pubmed/about'
			page.should have_selector('title',
						:text => "Dynamic Pubmed | About")
		end
	end
end