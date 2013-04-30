require 'spec_helper'

describe "Dynamic Pubmed pages" do

	subject { page }

	describe "Home page" do
		before { visit root_path }

		it { should have_selector('h1', text: 'Dynamic Pubmed')}
		it { should have_selector('title', text: 'Dynamic Pubmed')}
		it { should_not have_selector('title', text: '| Home')}
		it { should have_content('25')}
	end

	describe "Help page" do
		before { visit help_path }

		it { should have_selector('h1', text: 'Help')}
		it { should have_selector('title', text: 'Dynamic Pubmed | Help')}
	end

	describe "About page" do
		before { visit about_path }

		it { should have_selector('h1', text: 'About')}
		it { should have_selector('title', text: 'Dynamic Pubmed | About')}
	end

	describe "Contact page" do
		before { visit contact_path }

		it { should have_selector('h1', text: 'Contact')}
		it { should have_selector('title', text: 'Dynamic Pubmed | Contact')}
	end
end