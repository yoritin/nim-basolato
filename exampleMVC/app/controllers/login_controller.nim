import times, json, re, os
# 3rd party
import bcrypt
# import ../../../src/basolato/controller
import ../../../src/basolato/private
import ../../../src/basolato/session
# model
import ../models/users
# view
import ../../resources/login/create

const SALT = getEnv("SALT").string

type LoginController = ref object
  request: Request
  login: Login
  user: User

proc newLoginController*(request:Request): LoginController =
  return LoginController(
    request: request,
    login: initLogin(request),
    user: newUser()
  )

proc create*(this: LoginController): Response =
  return render(createHtml(this.login))

proc store*(this: LoginController): Response =
  let params = this.request.params
  let email = params["email"]
  let password = params["password"]

  # validation
  var errors = newJObject()
  if email.len == 0:
    errors.add("email", %"This is required field")
  elif not email.match(re"^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$"):
    errors.add("email", %"Invalid form of email")
  if not password.match(re"^[a-zA-Z\d]{8,100}$"):
    errors.add("password", %"A minimum 8 characters password contains a combination of uppercase and lowercase letter and number are required.")
  # get passsword
  let db_password = this.user.getPasswordByEmail(email)
  if db_password == "":
    errors.add("email", %"email is not match")
  # password check
  let hashed = hash(password, SALT)
  if not compare(hashed, db_password):
    errors.add("password", %"password is not match")

  if errors.len > 0:
    return render(createHtml(this.login, email, errors))
  return redirect("/posts")

proc destroy*(this: LoginController): Response =
  this.login.sessionDestroy()
  return redirect("/posts").deleteCookie("token")
