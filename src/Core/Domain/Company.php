<?php

declare(strict_types=1);

namespace App\Core\Domain;

use App\Core\Domain\ValueObject\Address;
use App\Core\Domain\ValueObject\EmailAddress;
use App\Core\Domain\ValueObject\PhoneNumber;
use App\Core\Domain\ValueObject\ShareCapital;
use App\Core\Domain\ValueObject\Siren;

final class Company
{
    public function __construct(
        private Siren $siren,
        private PhoneNumber $phoneNumber,
        private Address $address,
        private EmailAddress $email,
        private ShareCapital $shareCapital
    ) {
    }

    public function siren(): Siren
    {
        return $this->siren;
    }

    public function phoneNumber(): PhoneNumber
    {
        return $this->phoneNumber;
    }

    public function address(): Address
    {
        return $this->address;
    }

    public function email(): EmailAddress
    {
        return $this->email;
    }

    public function shareCapital(): ShareCapital
    {
        return $this->shareCapital;
    }

    public function toArray(): array
    {
        return [
            'siren'   => $this->siren->value(),
            'phone'   => $this->phoneNumber->value(),
            'address' => $this->address->value(),
            'email'   => $this->email->value(),
            'capital' => $this->shareCapital->value(),
        ];
    }
}
