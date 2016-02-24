How To Contribute
=================

We love pull requests! We simply don't have the time or resources to add every feature and support every platform. If you have improvements for Traffic Control, we're more than happy to merge them in.

We have a few guidelines to help maintain code quality and ensure the pull request process goes smoothly.

Remember, it doesn't have to be perfect. If you want to help, hack it together and submit a [pull request](https://help.github.com/articles/using-pull-requests/). We'll work with you to make sure it fits properly into the project.

Contributor License Agreement
-----------------------------
First things first, we need you to sign the [Contributor License Agreement (CLA)](http://traffic-control-cdn.net/ComcastContributorLicenseAgreement_03-07-14.pdf) before we can accept your code. This protects us, you, and everyone else using and contributing to Traffic Control.

Making a pull request
---------------------
If you've never made a pull request, it's super-easy. Github has a great tutorial [here](https://help.github.com/articles/using-pull-requests/). In a nutshell, you click the _fork_ button to make a fork, clone it and make your change, then click the green _New pull request_ button on your repository's Github page and follow the instructions. That's it! We'll look at it and get back to you.

Guidelines
----------
Following the project conventions will make the pull request process go faster and smoother.

#### Create an issue

If you want to add a new feature, make a Github issue to discuss it with us first. We might already be working on it, or there might be an existing way to do it.

If it's a bug fix, we need to know what the problem is and how to reproduce it.

#### Documentation

If your pull request changes the user interface or API, make sure the relevant documentation is updated.

#### Code formatting

Keep functions small. Big functions are hard to read, and hard to review. Try to make your changes look like the surrounding code, and follow language conventions. For Go, run `gofmt` and `go vet`. For Perl, `perltidy`. For Java, [PMD](https://pmd.github.io).

#### One pull request per feature

Like big functions, big pull requests are just hard to review. Make each pull request as small as possible. For example, if you're adding ten independent API endpoints, make each a separate pull request. If you're adding interdependent functions or endpoints to multiple components, make a pull request for each, starting at the lowest level. 

#### Tests

Make sure all existing tests pass. If you change the way something works, be sure to update tests to reflect the change. Add unit tests for new functions, and add integration tests for new interfaces.

Tests that fail if your feature doesn't work are much more useful than tests which only validate best-case scenarios.

We're in the process of adding more tests and testing frameworks, so if a testing framework doesn't exist for the component you're changing, don't worry about it.

#### Commit messages

Try to make your commit messages follow [git best practices](http://chris.beams.io/posts/git-commit/).

1. Separate subject from body with a blank line
2. Limit the subject line to 50 characters
3. Capitalize the subject line
4. Do not end the subject line with a period
5. Use the imperative mood in the subject line
6. Wrap the body at 72 characters
7. Use the body to explain what and why vs. how

This make it easier for people to read and understand what each commit does, on both the command line interface and Github.com.

---

Don't let all these guidelines discourage you, we're more interested in community involvement than perfection.

What are you waiting for? Get hacking!
