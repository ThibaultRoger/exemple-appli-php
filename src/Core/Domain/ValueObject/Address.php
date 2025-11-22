<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObject;

final class Address
{
    public function __construct(
        private string $value
    ) {
        if (trim($value) === '') {
            throw new \InvalidArgumentException('Address cannot be empty');
        }
    }

    public function value(): string
    {
        return $this->value;
    }
}
