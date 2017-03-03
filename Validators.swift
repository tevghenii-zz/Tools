
//    Copyright (c) 2017 Evghenii Todorov
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import Foundation

protocol Validation {
    func setValidStyle()
    func setErrorStyle(message: String?)
    var value: String? { get }
    var label: String { get }
}

class ValidatorRule {
    typealias RuleType = (String?) -> Bool
    
    let rule: RuleType
    var message: String?
    
    init(rule: @escaping RuleType) {
        self.rule = rule
    }
    
    func test(value: String?) -> Bool {
        return rule(value)
    }
}

class EmptyRule: ValidatorRule {
    
    required init(message: String?) {
        super.init { value -> Bool in
            guard let value = value else { return false }
            return !value.isEmpty
        }
        
        self.message = message
    }
}

class MinimumCharactersRule: ValidatorRule {
    
    required init(minimumLength: Int, message: String?) {
        super.init { value -> Bool in
            guard let value = value else { return false }
            return value.characters.count >= minimumLength
        }
        
        self.message = message
    }
}

class DigitCharactersRule: ValidatorRule {
    
    required init(message: String?) {
        super.init { value -> Bool in
            guard let value = value else { return false }
            let characterSet = CharacterSet(charactersIn: "0123456789").inverted
            return value.rangeOfCharacter(from: characterSet) == nil
        }
        
        self.message = message
    }
}

class PhoneNumberRule: ValidatorRule {
    
    required init(message: String?) {
        super.init { value -> Bool in
            guard let value = value else { return false }
            let characterSet = CharacterSet(charactersIn: "0123456789+ .()-*#").inverted
            return value.rangeOfCharacter(from: characterSet) == nil
        }
        
        self.message = message
    }
    
}

class Validator {
    
    private let subject: Validation
    private var rules: [ValidatorRule]
    
    init(subject: Validation) {
        self.subject = subject
        self.rules = []
    }
    
    var validValue: String? {
        let value = subject.value
        
        for rule in rules {
            if rule.test(value: value) == false {
                subject.setErrorStyle(message: rule.message)
                return nil
            }
        }
        
        subject.setValidStyle()
        return value
    }
    
    func addRule(_ rule: ValidatorRule) {
        rules.append(rule)
    }
}

class EmptyValueValidator: Validator {
    
    override init(subject: Validation) {
        super.init(subject: subject)
        
        addRule(EmptyRule(message: "\(subject.label) is empty."))
    }
    
}

class PasswordValidator: EmptyValueValidator {
    
    required init(subject: Validation, minLength: Int) {
        super.init(subject: subject)
        
        addRule(MinimumCharactersRule(minimumLength: minLength, message: "Minimum \(minLength) characters."))
    }
    
}

class MobileValidator: EmptyValueValidator {
    
    override init(subject: Validation) {
        super.init(subject: subject)
        
        addRule(PhoneNumberRule(message: "Wrong phone number"))
    }
    
}

class CodeValidator: EmptyValueValidator {
    
    required init(subject: Validation, minLength: Int) {
        super.init(subject: subject)
        
        addRule(MinimumCharactersRule(minimumLength: minLength, message: "\(subject.label) must have minimum \(minLength) characters."))
        addRule(DigitCharactersRule(message: "Please digits only"))
    }
}
