<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObject;

final class PhoneNumber
{
    public function __construct(
        private string $value
    ) {
        if (!preg_match('/^[+0-9][0-9\s]{5,}$/', $value)) {
            throw new \InvalidArgumentException(sprintf('Invalid phone number "%s"', $value));
        }
    }

    public function value(): string
    {
        return $this->value;
    }
}
