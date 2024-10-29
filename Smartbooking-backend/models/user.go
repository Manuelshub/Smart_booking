package model

import (
	"fmt"
	"log"

	"github.com/gofrs/uuid"
)

type User struct {
	UserID 	  	   string `json:"userId"`
	FirstName 	   string 	  `json:"firstname"`
	LastName  	   string     `json:"lastname"`
	Email 	  	   string     `json:"email"`
	Password  	   string     `json:"password"`
	WalletAddress  string     `json:"walletAddress"`
}


func (u *User)GenerateUserID() string {
	// Create a Version 4 UUID.
	userId, err := uuid.NewV4()
	if err != nil {
		log.Fatalf("Error generating UUID: %v\n", err)
	}
	return userId.String()
}

func (u *User)String() string {
	return fmt.Sprintf("%v %v %v %v %v %v", u.UserID, u.FirstName, u.LastName, u.Email, u.Password, u.WalletAddress)
}