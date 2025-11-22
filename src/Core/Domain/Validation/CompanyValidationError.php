<?php

declare(strict_types=1);

namespace App\Core\Domain\Validation;

final class CompanyValidationError
{
    /**
     * @param string[] $fields
     */
    public function __construct(
        private string $message,
        private array $fields
    ) {
    }

    public function message(): string
    {
        return $this->message;
    }

    /**
     * @return string[]
     */
    public function fields(): array
    {
        return $this->fields;
    }
}
